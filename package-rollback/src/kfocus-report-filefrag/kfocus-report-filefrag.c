/*
 * Copyright 2024 MindShare Inc.
 * Copyright 2003-2018 Theodore Ts'o.
 *
 * Adapted for the Kubuntu Focus by A. Rainbolt.
 *
 * Forked from the code for filefrag from e2fsprogs
 * (https://github.com/tytso/e2fsprogs), licensed under the GNU General Public
 * License version 2.
 *
 * Name     : kfocus-report-filefrag
 * Summary  : kfocus-report-filefrag directory1 [directory2...]
 * Purpose  : Descends through a directory tree and reports the fragmentation
 *            of all files in the tree.
 * Example  : kfocus-report-filefrag /usr
 * License  : GPLv2
 * Run By   : kfocus-btrfs-optimize-set
 * Spec     : 4201
 */

#ifndef _LARGEFILE_SOURCE
#define _LARGEFILE_SOURCE
#endif
#ifndef _LARGEFILE64_SOURCE
#define _LARGEFILE64_SOURCE
#endif


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/vfs.h>
#include <sys/ioctl.h>
#include <linux/fd.h>
#include <ext2fs/ext2fs.h>
#include <ext2fs/ext2_types.h>
#include <dirent.h>
#include "fiemap.h"

int force_bmap;    /* force use of FIBMAP instead of FIEMAP */
int logical_width = 8;
int physical_width = 10;

#define FILEFRAG_FIEMAP_FLAGS_COMPAT (FIEMAP_FLAG_SYNC | FIEMAP_FLAG_XATTR)

#define FIBMAP    _IO(0x00, 1)  /* bmap access */
#define FIGETBSZ  _IO(0x00, 2)  /* get the block size used for bmap */

#define  EXT4_EXTENTS_FL      0x00080000 /* Inode uses extents */
#define  EXT3_IOC_GETFLAGS    _IOR('f', 1, long)

static int ulong_log2(unsigned long arg)
{
  int     l = 0;

  arg >>= 1;
  while (arg) {
    l++;
    arg >>= 1;
  }
  return l;
}

static int ulong_log10(unsigned long long arg)
{
  int     l = 0;

  arg = arg / 10;
  while (arg) {
    l++;
    arg = arg / 10;
  }
  return l;
}

static int get_bmap(int fd, unsigned long block, unsigned long *phy_blk)
{
  int  ret;
  unsigned int b;

  b = block;
  ret = ioctl(fd, FIBMAP, &b); /* FIBMAP takes pointer to integer */
  if (ret < 0)
    return -errno;
  *phy_blk = b;

  return ret;
}

static int filefrag_fiemap(int fd, int blk_shift, int *num_extents,
         ext2fs_struct_stat *st)
{
  __u64 buf[2048];  /* __u64 for proper field alignment */
  struct fiemap *fiemap = (struct fiemap *)buf;
  struct fiemap_extent *fm_ext = &fiemap->fm_extents[0];
  struct fiemap_extent fm_last;
  int count = (sizeof(buf) - sizeof(*fiemap)) /
      sizeof(struct fiemap_extent);
  unsigned long long expected = 0;
  unsigned long long expected_dense = 0;
  unsigned long flags = 0;
  unsigned int i;
  unsigned long cmd = FS_IOC_FIEMAP;
  int tot_extents = 0, n = 0;
  int last = 0;
  int rc;

  memset(fiemap, 0, sizeof(struct fiemap));
  memset(&fm_last, 0, sizeof(fm_last));

  do {
    fiemap->fm_length = ~0ULL;
    fiemap->fm_flags = flags;
    fiemap->fm_extent_count = count;
    rc = ioctl(fd, cmd, (unsigned long) fiemap);
    if (rc < 0) {
      static int fiemap_incompat_printed;

      rc = -errno;
      if (rc == -EBADR && !fiemap_incompat_printed) {
        fprintf(stderr, "FIEMAP failed with unknown "
            "flags %x\n",
               fiemap->fm_flags);
        fiemap_incompat_printed = 1;
      }
      return rc;
    }

    /* If 0 extents are returned, then more ioctls are not needed */
    if (fiemap->fm_mapped_extents == 0)
      break;

    for (i = 0; i < fiemap->fm_mapped_extents; i++) {
      expected_dense = fm_last.fe_physical +
           fm_last.fe_length;
      expected = fm_last.fe_physical +
           fm_ext[i].fe_logical - fm_last.fe_logical;
      if (fm_ext[i].fe_logical != 0 &&
          fm_ext[i].fe_physical != expected &&
          fm_ext[i].fe_physical != expected_dense) {
        tot_extents++;
      } else {
        expected = 0;
        if (!tot_extents)
          tot_extents = 1;
      }
      if (fm_ext[i].fe_flags & FIEMAP_EXTENT_LAST)
        last = 1;
      fm_last = fm_ext[i];
      n++;
    }

    fiemap->fm_start = (fm_ext[i - 1].fe_logical +
            fm_ext[i - 1].fe_length);
  } while (last == 0);

  *num_extents = tot_extents;

  return 0;
}

static int filefrag_fibmap(int fd, int blk_shift, int *num_extents,
         ext2fs_struct_stat *st,
         unsigned long numblocks)
{
  struct fiemap_extent  fm_ext, fm_last;
  unsigned long    i, last_block;
  unsigned long long  logical, expected = 0;
  int      count;

  memset(&fm_ext, 0, sizeof(fm_ext));
  memset(&fm_last, 0, sizeof(fm_last));

  for (i = 0, logical = 0, *num_extents = 0, count = last_block = 0;
       i < numblocks;
       i++, logical += st->st_blksize) {
    unsigned long block = 0;
    int rc;

    rc = get_bmap(fd, i, &block);
    if (rc < 0)
      return rc;
    if (block == 0)
      continue;

    if (*num_extents == 0 || block != last_block + 1 ||
        fm_ext.fe_logical + fm_ext.fe_length != logical) {
      /*
       * This is the start of a new extent; figure out where
       * we expected it to be and report the extent.
       */
      if (*num_extents != 0 && fm_last.fe_length) {
        expected = fm_last.fe_physical +
          (fm_ext.fe_logical - fm_last.fe_logical);
        if (expected == fm_ext.fe_physical)
          expected = 0;
      }
      /* create the new extent */
      fm_last = fm_ext;
      (*num_extents)++;
      fm_ext.fe_physical = block * st->st_blksize;
      fm_ext.fe_logical = logical;
      fm_ext.fe_length = 0;
    }
    fm_ext.fe_length += st->st_blksize;
    last_block = block;
  }

  return count;
}

static int frag_report(const char *filename)
{
  static struct statfs fsinfo;
  static unsigned int blksize;
  ext2fs_struct_stat st;
  int    blk_shift;
  long    fd;
  unsigned long long  numblocks;
  int    data_blocks_per_cyl = 1;
  int    num_extents = 1, expected = ~0;
  static dev_t  last_device;
  int    width;
  struct stat fileinfo;
  off_t targetfrag;
  int    rc = 0;

  fd = open(filename, O_RDONLY);
  if (fd < 0) {
    rc = -errno;
    perror("open");
    return rc;
  }

  if (fstat(fd, &st) < 0) {
    rc = -errno;
    perror("fstat");
    goto out_close;
  }

  if ((last_device != st.st_dev) || !st.st_dev) {
    if (fstatfs(fd, &fsinfo) < 0) {
      rc = -errno;
      perror("fstatfs");
      goto out_close;
    }
    if ((ioctl(fd, FIGETBSZ, &blksize) < 0) || !blksize)
      blksize = fsinfo.f_bsize;
  }
  st.st_blksize = blksize;

  last_device = st.st_dev;

  width = ulong_log10(fsinfo.f_blocks);
  if (width > physical_width)
    physical_width = width;

  numblocks = (st.st_size + blksize - 1) / blksize;
  blk_shift = ulong_log2(blksize);

  width = ulong_log10(numblocks);
  if (width > logical_width)
    logical_width = width;

  if (!force_bmap) {
    rc = filefrag_fiemap(fd, blk_shift, &num_extents, &st);
    expected = 0;
  }

  if (force_bmap || rc < 0) { /* FIEMAP failed, try FIBMAP instead */
    expected = filefrag_fibmap(fd, blk_shift, &num_extents,
             &st, numblocks);
    if (expected < 0) {
      if (expected == -EINVAL || expected == -ENOTTY) {
        fprintf(stderr, "%s: FIBMAP%s unsupported\n",
          filename, force_bmap ? "" : "/FIEMAP");
      } else if (expected == -EPERM) {
        fprintf(stderr,
          "%s: FIBMAP requires root privileges\n",
          filename);
      } else {
        fprintf(stderr, "%s: FIBMAP error: %s",
          filename, strerror(expected));
      }
      rc = expected;
      goto out_close;
    } else {
      rc = 0;
    }
    expected = expected / data_blocks_per_cyl + 1;
  }

  if (stat(filename, &fileinfo) < 0) {
    rc = -errno;
    perror("stat");
    goto out_close;
  }
  /* target is 100 extents per gibibyte */
  targetfrag = ((fileinfo.st_size / (1024 * 1024 * 1024)) * 100) + 100;

  printf("%ld|%d|%ld|%s\n", num_extents - targetfrag, num_extents, targetfrag, filename);
out_close:
  close(fd);

  return rc;
}

int main(int argc, char**argv)
{
  char *targetdirname;
  char **infolist;
  char **filelist;
  size_t infolistlen;
  size_t filelistlen;
  size_t infolistcap;
  size_t filelistcap;
  off_t  infolistloc;
  DIR *targetdir;
  int rc = 0;

  if (2 > argc) {
    fprintf(stderr, "Invalid number of arguments\n");
    return 1;
  }

  for (int i = 1;i < argc;i++) {
    targetdirname = argv[i];
    if (-1 == access(targetdirname, R_OK)) {
      fprintf(stderr, "Cannot access directory %s for reading\n", targetdirname);
      return 1;
    }
  }

  infolist = calloc(100, sizeof(char *));
  filelist = calloc(100, sizeof(char *));
  if ((NULL == infolist) || (NULL == filelist)) {
    fprintf(stderr, "Out of memory!\n");
    return 1;
  }
  infolistlen = 0;
  filelistlen = 0;
  infolistloc = 0;
  infolistcap = 100;
  filelistcap = 100;

  for (int i = 1;i < argc;i++) {
    if (infolistlen == infolistcap) {
      infolistcap *= 2;
      infolist = reallocarray(infolist, infolistcap, sizeof(char *));
      if (NULL == infolist) {
        fprintf(stderr, "Out of memory!\n");
        return 1;
      }
    }

    infolist[infolistlen] = calloc(strlen(argv[i]) + 1, sizeof(char));
    strcpy(infolist[infolistlen], argv[i]);
    ++infolistlen;
  }

  while (infolistloc < infolistlen) {
    struct stat statdat;
    char *currentstr;
    
    currentstr = infolist[infolistloc];
    ++infolistloc;
    if (0 != lstat(currentstr, &statdat)) {
      perror("lstat");
      continue;
    }

    if (S_ISDIR(statdat.st_mode)) {
      struct dirent *dirdat;

      targetdir = opendir(currentstr);
      if (NULL == targetdir) {
        perror("opendir");
        continue;
      }

      while ((dirdat = readdir(targetdir)) != NULL) {
        if (!strcmp(".", dirdat->d_name) || !strcmp("..", dirdat->d_name)) {
          continue;
        }

        if (infolistlen == infolistcap) {
          infolistcap *= 2;
          infolist = reallocarray(infolist, infolistcap, sizeof(char *));
          if (NULL == infolist) {
            fprintf(stderr, "Out of memory!\n");
            return 1;
          }
        }

        infolist[infolistlen] = calloc(strlen(currentstr)
          + strlen(dirdat->d_name)
          + 2,
          sizeof(char));
        if (NULL == infolist[infolistlen]) {
          fprintf(stderr, "Out of memory!\n");
          return 1;
        }

        strcpy(infolist[infolistlen], currentstr);
        infolist[infolistlen][strlen(currentstr)] = '/';
        strcpy(infolist[infolistlen] + strlen(currentstr) + 1,
          dirdat->d_name);
        ++infolistlen;
      }

      closedir(targetdir);
    } else if (S_ISREG(statdat.st_mode)) {
      if (filelistlen == filelistcap) {
        filelistcap *= 2;
        filelist = reallocarray(filelist, filelistcap, sizeof(char *));
        if (NULL == filelist) {
          fprintf(stderr, "Out of memory!\n");
          return 1;
        }
      }

      filelist[filelistlen] = calloc(strlen(currentstr) + 1,
        sizeof(char));
      if (NULL == filelist[filelistlen]) {
        fprintf(stderr, "Out of memory!\n");
        return 1;
      }

      strcpy(filelist[filelistlen], currentstr);
      ++filelistlen;
    }
  }

  for (size_t i = 0; i < filelistlen; ++i) {
    int rc2 = frag_report(filelist[i]);
    if (rc2 < 0 && rc == 0) {
      rc = rc2;
    }
  }

  return -rc;
}
