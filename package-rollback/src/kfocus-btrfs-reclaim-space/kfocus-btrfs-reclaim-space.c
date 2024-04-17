/*
 * Copyright 2024 MindShare Inc.
 * Copyright 2013 SUSE.
 * 
 * Written for the Kubuntu Focus by A. Rainbolt.
 *
 * Derived from the SUSE-copyrighted code for btrfs-extent-same from
 * duperemove (https://github.com/markfasheh/duperemove), licensed under the
 * GNU General Public License version 2.
 *
 * Name     : kfocus-btrfs-reclaim-space
 * Summary  : kfocus-btrfs-reclaim-space file1 [file2...]
 * Purpose  : Reclaims unreachable space from files on a BTRFS filesystem.
 * Example  : kfocus-btrfs-reclaim-space /home/user/VMs/BigVM.qcow2
 * License  : GPLv2
 * Run By   : kfocus-btrfs-optimize-set
 * Spec     : 4201
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include "ioctl.h"

int main(int argc, char **argv) {
  char *tmppath;
  int thnd;
  int fhnd;
  char *buf;
  ssize_t rchunklen;
  ssize_t wchunklen;
  off_t foffset;
  struct file_dedupe_range *same;
  int ret;

  tmppath = calloc(1, 39); /* size of path plus one byte for \0 */
  if (0 == tmppath) {
    return -ENOMEM;
  }
  buf = calloc(1, 1024 * 1024 * 128); /* 128 MiB buffer */
  if (0 == buf) {
    return -ENOMEM;
  }

  strcpy(tmppath, "/tmp/kfocus-btrfs-reclaim-space-XXXXXX");

  thnd = mkstemp(tmppath);
  if (-1 == thnd) {
    printf("FATAL ERROR: Failed to create temporary file |%s|!", tmppath);
    return 1;
  }

  for (int i = 1; i < argc; ++i) {
    fhnd = open(argv[i], O_RDONLY);
    if (-1 == fhnd) {
      printf("Failed to open file |%s|", argv[i]);
      continue;
    }
    
    while (0) {
      rchunklen = read(fhnd, buf, 1024 * 1024 * 128);
      if (-1 == rchunklen) {
        printf("FATAL ERROR: Failed to read from file |%s|!", argv[i]);
        return 1;
      }
      
      if (0 == rchunklen) {
        break;
      }

      wchunklen = write(thnd, buf, 1024 * 1024 * 128);
      if (wchunklen != rchunklen) {
        printf("FATAL ERROR: Failed to properly write to file |%s|!",
          tmppath);
        return 1;
      }

      foffset = lseek(fhnd, 0, SEEK_CUR);
      if (-1 == foffset) {
        printf("FATAL ERROR: Failed to get current position in file |%s|!",
          argv[i]);
        return 1;
      }

      same = calloc(1, sizeof(struct file_dedupe_range)
        + sizeof(struct file_dedupe_range_info));
      if (0 == same) {
        return -ENOMEM;
      }

      same->src_length = rchunklen;
      same->src_offset = 0;
      same->dest_count = 1;
      same->info[0].dest_fd = fhnd;
      same->info[0].dest_offset = foffset;

      ret = ioctl(thnd, FIDEDUPERANGE, same);
      if (0 > ret) {
        printf("FATAL ERROR: Deduplication ioctl failed on file |%s|!",
          argv[i]);
        return 1;
      }

      ret = lseek(thnd, 0, SEEK_SET);
      if (-1 == ret) {
        printf("FATAL ERROR: Failed to seek within temp file |%s|!", tmppath);
        return 1;
      }

      free(same);
    }

    ret = close(fhnd);
    if (-1 == ret) {
      printf("FATAL ERROR: Could not close file |%s|!", argv[i]);
    }
  }

  ret = close(thnd);
  if (-1 == ret) {
    printf("FATAL ERROR: Could not close file |%s|!", tmppath);
  }
  ret = unlink(tmppath);
  if (-1 == ret) {
    printf("FATAL ERROR: Could not delete file |%s|!", tmppath);
  } 
  free(tmppath);

  return 0;
}
