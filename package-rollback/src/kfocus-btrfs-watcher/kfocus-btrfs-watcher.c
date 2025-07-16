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
#include <linux/limits.h>
#include <poll.h>
#include <stdbool.h>
#include <limits.h>

void *safe_calloc(size_t nmemb, size_t size) {
  void *ptr = calloc(nmemb, size);
  if (ptr == NULL) {
    perror("Cannot allocate memory");
    exit(1);
  }
  return ptr;
}

enum fs_info {
  SIZE,
  USED
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
    } else if (info_type == USED) {
      fs_val += dev_info.bytes_used;
    }
  }

  return fs_val;
}

bool timespec_compare_ge(struct timespec tsbig, struct timespec tssmall) {
  if (tsbig.tv_sec == tssmall.tv_sec) {
    if (tsbig.tv_nsec >= tssmall.tv_nsec) {
      return true;
    }
    return false;
  }
  if (tsbig.tv_sec >= tssmall.tv_sec) {
    return true;
  }
  return false;
}

int get_poll_timeout(struct timespec *debounce_ts_list,
  struct timespec *debounce_max_ts_list, bool *fs_mod_flag_list,
  size_t path_data_len, struct timespec ts) {

  int solve_timeout_ms = INT_MAX;
  int current_timeout;

  for (size_t i = 0; i < path_data_len; ++i) {
    if (!fs_mod_flag_list[i]) {
      continue;
    }
    if (timespec_compare_ge(debounce_ts_list[i], ts)) {
      current_timeout = ((debounce_ts_list[i].tv_sec - ts.tv_sec) * 1000)
        + ((debounce_ts_list[i].tv_nsec - ts.tv_nsec) / 1000000);
      if (current_timeout < solve_timeout_ms) {
        solve_timeout_ms = current_timeout;
      }
    }
  }

  for (size_t i = 0; i < path_data_len; ++i) {
    if (!fs_mod_flag_list[i]) {
      continue;
    }
    if (timespec_compare_ge(debounce_max_ts_list[i], ts)) {
      current_timeout = ((debounce_max_ts_list[i].tv_sec - ts.tv_sec) * 1000)
        + ((debounce_ts_list[i].tv_nsec - ts.tv_nsec) / 1000000);
      if (current_timeout < solve_timeout_ms) {
        solve_timeout_ms = current_timeout;
      }
    }
  }

  if (solve_timeout_ms == INT_MAX) {
    return -1;
  }
  solve_timeout_ms += 1; /* don't trigger just before a timer expires */
  return solve_timeout_ms;
}

int main(int argc, char **argv) {
  /* Parameters */
  const char *path_data[] = { "/", "/boot", NULL };
  //const char *path_data[] = { "/boot", NULL };

  /* The threshold_pct_list array specifies the percentage of unallocated
   * space each filesystem in path_data must have. If free space dips below
   * this value, a warning should be displayed to the user for the
   * corresponding filesystem. This array MUST have the same number of
   * elements as path_data, minus 1. It should NOT be NULL-terminated. */
  const uint8_t threshold_pct_list[] = { 15, 25 };

  /* The warn_cmd_list array specifies the shell command that should be run to
   * display a warning message to a user if the corresponding filesystem's
   * unallocated space dips below the threshold. The strings in this array
   * will be passed through to system() unmodified. */
  const char *warn_cmd_list[] = {
    "/usr/lib/kfocus/bin/kfocus-rollback-backend checkMainUnallocSpace",
    "/usr/lib/kfocus/bin/kfocus-rollback-backend checkBootUnallocSpace",
  };

  /* Working variables */
  size_t path_data_len = 0;
  int *path_fd_list;
  int *fan_fd_list;
  struct pollfd *fan_poll_list;
  bool *fs_mod_flag_list;
  struct timespec *debounce_ts_list;
  struct timespec *debounce_max_ts_list;
  uint64_t *fs_size_list;
  uint64_t *fs_alloc_threshold_list;
  time_t *fs_overfull_timeout_list;
  struct stat statbuf;
  struct statfs statfsbuf;
  uint64_t fs_alloc = 0;
  char fanbuf[4096];
  uint32_t fanlen;
  struct fanotify_event_metadata *fem = NULL;
  struct timespec ts = { 0 };

  /* Allocate memory for working variable arrays */
  while (true) {
    ++path_data_len;
    if (path_data[path_data_len] == NULL) {
      break;
    }
  }
  path_fd_list             = safe_calloc(path_data_len, sizeof(int));
  fan_fd_list              = safe_calloc(path_data_len, sizeof(int));
  fan_poll_list            = safe_calloc(path_data_len, sizeof(struct pollfd));
  fs_mod_flag_list         = safe_calloc(path_data_len, sizeof(bool));
  debounce_ts_list         = safe_calloc(path_data_len, sizeof(struct timespec));
  debounce_max_ts_list     = safe_calloc(path_data_len, sizeof(struct timespec));
  fs_size_list             = safe_calloc(path_data_len, sizeof(uint64_t));
  fs_alloc_threshold_list  = safe_calloc(path_data_len, sizeof(uint64_t));
  fs_overfull_timeout_list = safe_calloc(path_data_len, sizeof(time_t));

  /* Open and register paths */
  for (size_t i = 0; i < path_data_len; ++i) {
    const char *current_path = path_data[i];
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
    fan_fd_list[i] = fanotify_init(FAN_CLASS_NOTIF, FAN_CLOEXEC);
    fan_poll_list[i].fd = fan_fd_list[i];
    fan_poll_list[i].events = POLLIN;
    if (fanotify_mark(
      fan_fd_list[i],
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
  while (
    poll(
      fan_poll_list,
      path_data_len,
      get_poll_timeout(
        debounce_ts_list,
        debounce_max_ts_list,
        fs_mod_flag_list,
        path_data_len,
        ts
      )
    ) != -1) {

    if (clock_gettime(CLOCK_MONOTONIC, &ts) == -1) {
      fprintf(stderr, "failed to get time: ");
      perror(NULL);
      exit(1);
    }

    for (size_t i = 0; i < path_data_len; ++i) {
      if (fan_poll_list[i].revents & POLLIN) {
        if (!fs_mod_flag_list[i]) {
          debounce_max_ts_list[i] = ts;
          debounce_max_ts_list[i].tv_sec += 5;
        }
        debounce_ts_list[i] = ts;
        debounce_ts_list[i].tv_sec += 1;
        fs_mod_flag_list[i] = true;

        fanlen = read(fan_fd_list[i], fanbuf, sizeof(fanbuf));
        if (fanlen < 0) {
          fprintf(stderr, "Failed to read fanotify events for path |%s|: ", path_data[i]);
          exit(1);
        }
        fem = (void *)fanbuf;
        while (FAN_EVENT_OK(fem, fanlen)) {
          if (fem != NULL) {
            close(fem->fd);
          }
          fem = FAN_EVENT_NEXT(fem, fanlen);
        }
      }

      if (!fs_mod_flag_list[i]) {
        continue;
      }

      if (timespec_compare_ge(debounce_ts_list[i], ts)
        && timespec_compare_ge(debounce_max_ts_list[i], ts)) {
        continue;
      }
      fs_mod_flag_list[i] = false;

      fs_alloc = get_btrfs_fs_info(path_fd_list[i], path_data[i], USED);

      if ((fs_size_list[i] - fs_alloc) >= fs_alloc_threshold_list[i]) {
        continue;
      }

      close(fem->fd);

      /* Unallocated space is insufficient, display a warning to the user if
       * we haven't displayed one within the last hour */
      if (fs_overfull_timeout_list[i] < ts.tv_sec) {
        /* 3600 seconds = 1 hour */
        fs_overfull_timeout_list[i] = ts.tv_sec + 3600;
        if (system(warn_cmd_list[i]) == -1) {
          fprintf(stderr, "Failed to trigger warning message for filesystem |%s|: ", path_data[i]);
          perror(NULL);
          exit(1);
        }
      }
    }
  }

  perror("Failed to poll fanoitfy file descriptors");
  exit(1);
}
