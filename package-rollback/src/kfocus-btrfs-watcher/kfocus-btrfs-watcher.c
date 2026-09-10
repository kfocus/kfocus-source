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
#include <signal.h>
#include <assert.h>

#define HOUR_SEC_COUNT 3600
#define MAINT_TIMER_PATH "/var/lib/kfocus/btrfs_maint_timer"
/* 4 hours, in milliseconds */
#define MAINT_TIMER_EXP_MS 14400000
/* 5 minutes, in milliseconds */
#define MAINT_BOOT_THRESH_MS 300000

bool main_loop_active = false;
bool prepare_to_terminate = false;

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

void signal_handler(int signal_num) {
  if (!main_loop_active) {
    _exit(0);
  }
  prepare_to_terminate = true;
}

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
  size_t path_data_len, uint32_t maint_timer_ms, struct timespec ts) {

  int solve_timeout_ms = INT_MAX;
  int current_timeout;

  for (size_t i = 0; i < path_data_len; ++i) {
    if (!fs_mod_flag_list[i]) {
      continue;
    }
    if (timespec_compare_ge(debounce_ts_list[i], ts)) {
      current_timeout = (int)(((debounce_ts_list[i].tv_sec - ts.tv_sec)
        * 1000) + ((debounce_ts_list[i].tv_nsec - ts.tv_nsec) / 1000000));
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
      current_timeout = (int)(((debounce_max_ts_list[i].tv_sec - ts.tv_sec)
        * 1000) + ((debounce_ts_list[i].tv_nsec - ts.tv_nsec) / 1000000));
      if (current_timeout < solve_timeout_ms) {
        solve_timeout_ms = current_timeout;
      }
    }
  }

  if (maint_timer_ms > INT_MAX) {
    maint_timer_ms = INT_MAX;
  }
  current_timeout = MAINT_TIMER_EXP_MS - (int)(maint_timer_ms);
  if (current_timeout < 0) {
    current_timeout = 0;
  }
  if (current_timeout < solve_timeout_ms) {
    solve_timeout_ms = current_timeout;
  }

  assert(solve_timeout_ms < INT_MAX);
  assert(solve_timeout_ms > 0);
  solve_timeout_ms += 1; /* don't trigger just before a timer expires */
  return solve_timeout_ms;
}

uint32_t load_maint_timer() {
  int maint_timer_fd = 0;
  off_t maint_timer_len = 0;
  char *maint_timer_buf = NULL;
  ssize_t maint_read_len = 0;
  uint8_t read_attempt_count = 0;
  uint32_t ret_val = 0;
  char *check_ptr = NULL;
  unsigned long parse_rslt = 0;

  maint_timer_fd = open(MAINT_TIMER_PATH, O_RDONLY);
  if (maint_timer_fd == -1) {
    goto cleanup;
  }
  maint_timer_len = lseek(maint_timer_fd, 0, SEEK_END);
  if (maint_timer_len <= 0) {
    goto cleanup;
  }
  /* Largest possible 32-bit integer is 10 decimal digits, take into account
   * the newline at the end of text files */
  if (maint_timer_len > 11) {
    goto cleanup;
  }
  maint_timer_buf = safe_calloc((size_t)(maint_timer_len), sizeof(char));

  /* Retrying the read until we get a complete read is easy. This is only 11
   * characters max, so the chances of us getting a partial read are
   * vanishingly small. Give up after three tries. */
  while (maint_read_len != maint_timer_len && read_attempt_count < 3) {
    if (lseek(maint_timer_fd, 0, SEEK_SET) == -1) {
      goto cleanup;
    }
    maint_read_len = read(maint_timer_fd, maint_timer_buf,
      (size_t)(maint_timer_len));
    read_attempt_count++;
  }
  close(maint_timer_fd);
  maint_timer_fd = 0;
  if (maint_read_len != maint_timer_len) {
    goto cleanup;
  }

  /* Validate and NULL-terminate */
  if (maint_timer_buf[0] == '\0') {
    goto cleanup;
  }
  if (maint_timer_buf[maint_timer_len - 1] != '\n') {
    goto cleanup;
  }
  maint_timer_buf[maint_timer_len - 1] = '\0';

  /* Technically if there is a NULL earlier in the string, this could be
   * fooled, but the file is owned by root, so we don't have to be worried
   * about it being malicious. */
  parse_rslt = strtoul(maint_timer_buf, &check_ptr, 10);
  if (*check_ptr != '\0') {
    goto cleanup;
  }
  if (parse_rslt > UINT32_MAX) {
    goto cleanup;
  }
  ret_val = (uint32_t)(parse_rslt);

cleanup:
  if (maint_timer_fd > 0) {
    close(maint_timer_fd);
  }
  if (maint_timer_buf != NULL) {
    free(maint_timer_buf);
  }
  return ret_val;
}

void try_save_maint_timer(uint32_t maint_timer_ms) {
  int maint_timer_fd = 0;
  char *timer_buf = NULL;
  int timer_buf_len = 0;
  ssize_t write_len = 0;

  maint_timer_fd = open(MAINT_TIMER_PATH, O_CREAT | O_WRONLY | O_TRUNC, 0644);
  if (maint_timer_fd == -1) {
    goto cleanup;
  }

  timer_buf_len = snprintf(NULL, 0, "%d\n", maint_timer_ms);
  if (timer_buf_len < 0) {
    goto cleanup;
  }
  timer_buf_len++;
  timer_buf = safe_calloc((size_t)(timer_buf_len), sizeof(char));
  snprintf(timer_buf, (size_t)(timer_buf_len), "%d\n", maint_timer_ms);

  write_len = write(maint_timer_fd, timer_buf, (size_t)(timer_buf_len - 1));
  if (write_len == -1) {
    perror("Could not save timestamp");
    exit(1);
  }
  if (write_len != timer_buf_len - 1) {
    fprintf(stderr, "WARNING: Partial write while saving timestamp!\n");
  }

cleanup:
  if (maint_timer_fd > 0) {
    close(maint_timer_fd);
  }
  if (timer_buf != NULL) {
    free(timer_buf);
  }
}

int main(int argc, char **argv) {
  /* Parameters */
  const char *path_data[] = { "/", "/boot", NULL };
  /* DEBUG: const char *path_data[] = { "/boot", NULL }; */

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
  ssize_t fanlen;
  struct fanotify_event_metadata *fem = NULL;
  struct timespec ts = { 0 };
  struct timespec last_ts = { 0 };
  uint32_t maint_timer_ms = 0;
  uint32_t elapsed_ms = 0;
  struct sigaction act = { 0 };

  /* Set up a signal handler */
  act.sa_handler = signal_handler;
  sigemptyset(&act.sa_mask);
  if (sigaction(SIGTERM, &act, NULL) == -1) {
    perror("Cannot set up signal handler");
    exit(1);
  }

  /* Initialize timestamp */
  if (clock_gettime(CLOCK_MONOTONIC, &ts) == -1) {
    fprintf(stderr, "failed to get time: ");
    perror(NULL);
    exit(1);
  }
  last_ts = ts;

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
    if (path_fd_list[i] < 0) {
      fprintf(stderr, "Cannot open path |%s|: ", current_path);
      perror(NULL);
      exit(1);
    }
    fan_fd_list[i] = fanotify_init(FAN_CLASS_NOTIF | FAN_CLOEXEC, O_CLOEXEC);
    if (fan_fd_list[i] < 0) {
      fprintf(stderr, "Failed to initialize fanotify watcher for |%s|: ",
        current_path);
      perror(NULL);
      exit(1);
    }
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

  /* Load maintenance timer duration from file */
  maint_timer_ms = load_maint_timer();
  /* Avoid triggering maintenance within five minutes of bootup
   * Need to check both before and after adding MAINT_BOOT_THRESH_MS to
   * account for potential overflow */
  if (maint_timer_ms >= MAINT_TIMER_EXP_MS
    || (maint_timer_ms + MAINT_BOOT_THRESH_MS) >= MAINT_TIMER_EXP_MS) {
    maint_timer_ms = MAINT_TIMER_EXP_MS - MAINT_BOOT_THRESH_MS;
  }

  /* fanotify event loop */
  main_loop_active = true;
  while (
    poll(
      fan_poll_list,
      path_data_len,
      get_poll_timeout(
        debounce_ts_list,
        debounce_max_ts_list,
        fs_mod_flag_list,
        path_data_len,
        maint_timer_ms,
        ts
      )
    ) != -1 || errno == EINTR) {

    if (clock_gettime(CLOCK_MONOTONIC, &ts) == -1) {
      fprintf(stderr, "failed to get time: ");
      perror(NULL);
      exit(1);
    }
    elapsed_ms = (uint32_t)(
        ((ts.tv_sec      * 1000) + (ts.tv_nsec      / 1000000))
      - ((last_ts.tv_sec * 1000) + (last_ts.tv_nsec / 1000000))
    );
    maint_timer_ms += elapsed_ms;
    last_ts = ts;

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
          if (errno == EAGAIN || errno == EWOULDBLOCK || errno == EINTR) {
            continue;
          }
          fprintf(stderr, "Failed to read fanotify events for path |%s|! Error code: %d\n", path_data[i], errno);
          exit(1);
        }
        if (fanlen == 0) {
          fprintf(stderr, "Event triggered but absent for path |%s|, fanotify hung up?\n", path_data[i]);
          exit(1);
        }
        /*
         * Debug
         * fprintf(stderr, "fanlen: %ld\n", fanlen);
         */
        fem = (void *)fanbuf;
        while (FAN_EVENT_OK(fem, fanlen)) {
          /*
           * Debug
           * fprintf(stderr, "fanotify fd close loop iteration\n");
           */
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

      /*
       * DEBUG:
       * printf("Path: %s\n", path_data[i]);
       * printf("Size: %lu\n", fs_size_list[i]);
       * printf("Alloc: %lu\n", fs_alloc);
       * printf("Min unalloc: %lu\n", fs_alloc_threshold_list[i]);
       * printf("-----------------\n");
       */

      fs_alloc = get_btrfs_fs_info(path_fd_list[i], path_data[i], USED);
      if ((fs_size_list[i] - fs_alloc) >= fs_alloc_threshold_list[i]) {
        continue;
      }

      close(fem->fd);

      /* Unallocated space is insufficient, display a warning to the user if
       * we haven't displayed one within the last hour */
      if (fs_overfull_timeout_list[i] < ts.tv_sec) {
        fs_overfull_timeout_list[i] = ts.tv_sec + HOUR_SEC_COUNT;
        if (system(warn_cmd_list[i]) == -1) {
          fprintf(stderr, "Failed to trigger warning message for filesystem |%s|: ", path_data[i]);
          perror(NULL);
          exit(1);
        }
      }
    }

    if (maint_timer_ms >= MAINT_TIMER_EXP_MS) {
      if (system("/usr/lib/kfocus/bin/kfocus-focusrx-system -s") != 0) {
        fprintf(stderr, "WARNING: |kfocus-focusrx-system -s| errored out!\n");
      }
      maint_timer_ms = 0;
    }

    if (prepare_to_terminate) {
      try_save_maint_timer(maint_timer_ms);
      exit(0);
    }
  }

  perror("Failed to poll fanoitfy file descriptors");
  exit(1);
}
