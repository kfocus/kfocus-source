/*
 * Copyright 2025 MindShare Inc.
 *
 * Written for the Kubuntu Focus by A. Rainbolt and M. Mikowski
 *
 * Name     : kfocus-btrfs-watcher
 * Summary  : kfocus-btrfs-watcher
 * Purpose  : Monitors the root and boot subvolumes for
 * Example  :
 * License  : GPLv2
 * Run By   : systemd
 * Spec     : 5133
 */

#include <btrfs/ioctl.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <linux/fanotify.h>
#include <sys/vfs.h>
#include <sys/fanotify.h>
#include <linux/magic.h>
#include <time.h>

#define PATH_DATA_LEN 2

char *fd_to_path(int fd) {
  const char *base = "/proc/self/fd";
  ssize_t init_path_size;
  char *init_path;
  struct stat statbuf = { 0 };
  int ret;
  char *final_path;
  ssize_t rl_len;

  init_path_size = snprintf(NULL, 0, "%s/%d", base, fd);
  init_path = malloc(init_path_size + 1);
  snprintf(init_path, init_path_size + 1, "%s/%d", base, fd);

  while (1) {
    ret = lstat(init_path, &statbuf);
    if (ret == -1) {
      perror("fd_to_path stat failed");
      exit(1);
    }
    final_path = malloc(statbuf.st_size + 1);
    rl_len = readlink(init_path, final_path, statbuf.st_size + 1);
    if (rl_len == -1) {
      perror("fd_to_path readlink failed");
      exit(1);
    } else if (rl_len == statbuf.st_size + 1) {
      // Path value changed out from under us, try again
      free(final_path);
      continue;
    }
    break;
  }

  free(init_path);
  final_path = realloc(final_path, rl_len);
  return final_path;
}

enum fs_info {
  SIZE,
  UNALLOC
};

uint64_t get_btrfs_fs_info(int fd, const char *path, enum fs_info info_type) {
  struct btrfs_ioctl_fs_info_args fi_args = { 0 };
  struct btrfs_ioctl_dev_info_args dev_info = { 0 };
  uint64_t fs_val = 0;

  if (ioctl(fd, BTRFS_IOC_FS_INFO, &fi_args) == -1) {
    fprintf(stderr, "FS info ioctl failed on path |%s|: ", path);
    perror(NULL);
    exit(1);
  }

  for (size_t i = 0; i <= fi_args.max_id; ++i) {
    memset(&dev_info, 0, sizeof(dev_info));
    dev_info.devid = i;
    if (ioctl(fd, BTRFS_IOC_DEV_INFO, &dev_info) == -1) {
      continue;
    }

    if (info_type == SIZE) {
      fs_val += dev_info.total_bytes;
    } else if (info_type == UNALLOC) {
      fs_val += dev_info.bytes_used;
    }
  }

  return fs_val;
}

ssize_t get_best_matching_path(const char ***path_data, const char *path) {
  ssize_t match_idx = -1;
  size_t match_len = 0;

  for (size_t i = 0; i < PATH_DATA_LEN; ++i) {
    for (size_t j = 0; path_data[i][j] != NULL; ++j) {
      size_t idx_len = strlen(path_data[i][j]);
      if (idx_len < match_len) {
        continue;
      }
      if (strncmp(path_data[i][j], path, idx_len) == 0) {
        match_idx = i;
        match_len = idx_len;
      }
    }
  }

  return match_idx;
}

int main(int argc, char **argv) {
  /* Parameters */
  const char *path_data_main[] = {
    "/",
    "/btrfs_main",
    "/etc/libvirt",
    "/var/lib/libvirt",
    NULL,
  };
  const char *path_data_boot[] = {
    "/boot",
    "/btrfs_boot",
    NULL,
  };
  const char **path_data[] = { path_data_main, path_data_boot };
  const uint8_t threshold_pct_list[PATH_DATA_LEN] = { 15, 25 };

  /* Working variables */
  int path_fd_list[PATH_DATA_LEN] = { 0, 0 };
  uint64_t fs_size_list[PATH_DATA_LEN] = { 0, 0 };
  uint64_t fs_alloc_threshold_list[PATH_DATA_LEN] = { 0, 0 };
  time_t fs_overfull_timeout_list[PATH_DATA_LEN] = { 0, 0 };
  struct stat statbuf;
  struct statfs statfsbuf;
  uint64_t fs_alloc;

  /* fanotify stuff */
  int fanfd;
  char fanbuf[4096];
  struct fanotify_event_metadata *fem = NULL;
  struct fanotify_event_metadata *next_fem = NULL;
  uint32_t fanlen;

  /* Initialize fanotify */
  fanfd = fanotify_init(FAN_CLASS_NOTIF, FAN_CLOEXEC);
  if (fanfd < 0) {
    perror("Cannot initialize fanotify");
    return 1;
  }

  /* Open and register paths */
  for (size_t i = 0; i < PATH_DATA_LEN; ++i) {
    const char *current_path = path_data[i][0];
    if (access(current_path, R_OK) == -1) {
      fprintf(stderr, "Cannot access path |%s|: ", current_path);
      perror(NULL);
      exit(1);
    }
    if (stat(current_path, &statbuf) == -1) {
      fprintf(stderr, "Cannot stat path |%s|: ", current_path);
      perror(NULL);
      exit(1);
    }
    if (!(statbuf.st_mode & S_IFDIR)) {
      fprintf(stderr, "Path |%s| is not a directory!\n", current_path);
      exit(1);
    }
    if (statfs(current_path, &statfsbuf) == -1) {
      fprintf(stderr, "Cannot statfs path |%s|: ", current_path);
      perror(NULL);
      exit(1);
    }
    if (statfsbuf.f_type != BTRFS_SUPER_MAGIC) {
      fprintf(stderr, "Path |%s| is not on a BTRFS filesystem!\n", current_path);
      exit(1);
    }

    path_fd_list[i] = open(current_path, O_RDONLY);
    if (fanotify_mark(
      fanfd,
      FAN_MARK_ADD | FAN_MARK_FILESYSTEM,
      FAN_CLOSE_WRITE,
      AT_FDCWD,
      current_path
    ) == -1) {
      fprintf(stderr, "Cannot add fanotify mark on path |%s|: ", current_path);
      perror(NULL);
      exit(1);
    }

    /* Get filesystem sizes and calculate minimum unallocated space thresholds
     * from that */
    fs_size_list[i] = get_btrfs_fs_info(
      path_fd_list[i], current_path, SIZE
    );
    fs_alloc_threshold_list[i] = (fs_size_list[i] * threshold_pct_list[i]) / 100;
  }

  /* fanotify event loop */
  while ((fanlen = read(fanfd, fanbuf, sizeof(fanbuf))) > 0) {
    ssize_t event_path_idx = -1;
    const char *event_path = NULL;

    fem = NULL;
    next_fem = (void *)fanbuf;

    while (FAN_EVENT_OK(next_fem, fanlen)) {
      if (fem != NULL) {
        close(fem->fd);
      }
      fem = next_fem;
      next_fem = FAN_EVENT_NEXT(next_fem, fanlen);
    }

    /* next_fem is now invalid, fem has the last event from the buffer */
    if (fem->vers < 2) {
      fprintf(stderr, "fanotify version is too old!\n");
      exit(1);
    }

    /* Find the primary mountpoint of the filesystem a file was changed on,
     * and check if it has sufficient unallocated space */
    event_path_idx = get_best_matching_path(path_data, fd_to_path(fem->fd));
    if (event_path_idx == -1) {
      continue;
    }
    event_path = path_data[event_path_idx][0];

    fs_alloc = get_btrfs_fs_info(path_fd_list[event_path_idx], event_path, UNALLOC);

    if (fs_alloc < fs_alloc_threshold_list[event_path_idx]) {
      /* Unallocated space is insufficient, display a warning to the user if
       * we haven't displayed one within the last hour */
      struct timespec ts;
      if (clock_gettime(CLOCK_MONOTONIC, &ts) == -1) {
        fprintf(stderr, "failed to get time: ");
        perror(NULL);
        exit(1);
      }
      if (fs_overfull_timeout_list[event_path_idx] < ts.tv_sec) {
        /* 3600 seconds = 1 hour */
        fs_overfull_timeout_list[event_path_idx] = ts.tv_sec + 3600;
        if (strcmp(event_path, "/") == 0) {
          system("/usr/lib/kfocus/bin/kfocus-rollback-backend checkMainUnallocSpace");
        } else if (strcmp(event_path, "/boot") == 0) {
          system("/usr/lib/kfocus/bin/kfocus-rollback-backend checkBootUnallocSpace");
        }
      }
    }

    /* TODO: Debugging, remove later */
    printf("Path: %s\n", event_path);
    printf("Size: %lu\n", fs_size_list[event_path_idx]);
    printf("Unalloc: %lu\n", fs_alloc);
    printf("Min unalloc: %lu\n", fs_alloc_threshold_list[event_path_idx]);

    close(fem->fd);
  }
}
