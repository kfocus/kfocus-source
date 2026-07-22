/*
 * Copyright 2026 MindShare Inc.
 *
 * Written for the Kubuntu Focus by A. Rainbolt.
 *
 * Name     : kfocus-fand
 * Summary  : kfocus-fand
 * Purpose  : Controls system fan speed using a fan curve.
 * Example  : kfocus-fand
 * License  : GPLv2
 * Run By   : systemd
 * Spec     : 6593
 */

#include <assert.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/signalfd.h>
#include <sys/stat.h>

#include <asm/ioctl.h>

#include <systemd/sd-daemon.h>

#define CONTROL_DEV_PATH      "/dev/tuxedo_io"
#define FAN_PROFILE_DB_PATH   "/usr/share/kfocus/kfocus_fand.d/fan_profile_db"
#define STATE_DIR_PATH        "/var/lib/kfocus"
#define FAN_CONFIG_PATH       "/var/lib/kfocus/fan_state"
#define FAN_PROFILE_COUNT     4
#define MAX_FAN_COUNT         3
#define POLL_WAIT_MS          1000
#define WATCHDOG_INTERVAL_SEC 3

/* ioctl macros taken from kfocus-keyboard/src/tuxedo_io/tuxedo_io_ioctl.h */

#define IOCTL_MAGIC    0xEC
#define MAGIC_READ_CL  IOCTL_MAGIC + 1
#define MAGIC_WRITE_CL IOCTL_MAGIC + 2
#define R_CL_FANINFO1  _IOR(MAGIC_READ_CL,  0x10, int32_t*)
#define R_CL_FANINFO2  _IOR(MAGIC_READ_CL,  0x11, int32_t*)
#define R_CL_FANINFO3  _IOR(MAGIC_READ_CL,  0x12, int32_t*)
#define W_CL_FANSPEED  _IOW(MAGIC_WRITE_CL, 0x10, int32_t*)
#define W_CL_FANAUTO   _IOW(MAGIC_WRITE_CL, 0x11, int32_t*)

static int     driver_handle = -1;
static int16_t fan_profile_data[FAN_PROFILE_COUNT][MAX_FAN_COUNT][256];
static bool    fan_profile_present_list[FAN_PROFILE_COUNT];
static int16_t active_fan_speed_list[MAX_FAN_COUNT];
static char *  fan_profile_header_list[FAN_PROFILE_COUNT] = {
  "=quiet",
  "=balanced",
  "=performance",
  "=max",
};
static int     signal_handle   = -1;
struct pollfd  poll_watch      = { 0 };
static ssize_t fan_profile_idx = -1;

static void flock_exclusive_safe(int target_file, const char *path) {
  while (true) {
    int flock_rslt = flock(target_file, LOCK_EX);
    if (flock_rslt != -1) {
      break;
    }
    if (errno == EINTR) {
      continue;
    }
    err(1, "Could not flock |%s|", path);
  }
}

static char *read_text_file(const char *path, bool do_flock) {
  int     target_file   = 0;
  off_t   file_len      = 0;
  char   *file_contents = NULL;
  ssize_t file_pos      = 0;
  ssize_t read_bytes    = 0;

  target_file = open(path, O_RDONLY);
  if (target_file == -1) {
    warn("Could not open file |%s| for reading", path);
    return NULL;
  }

  if (do_flock) {
    flock_exclusive_safe(target_file, path);
  }

  file_len = lseek(target_file, 0, SEEK_END);
  if (file_len < 0) {
    err(1, "Could not get length of file |%s|", path);
  }
  if (file_len == 0) {
    warnx("File |%s| is empty\n", path);
    close(target_file);
    return NULL;
  }
  if (lseek(target_file, 0, SEEK_SET) == -1) {
    err(1, "Could not seek to beginning of file |%s|", path);
  }

  /* Contents buffer size = file size + 1 to hold a NUL terminator */
  file_contents = calloc(file_len + 1, sizeof(char));
  if (file_contents == NULL) {
    err(1, "Could not allocate buffer for file contents");
  }

  while ((read_bytes = read(
    target_file, file_contents + file_pos, file_len)) > 0) {
    file_len -= read_bytes;
    file_pos += read_bytes;
  }
  if (read_bytes < 0) {
    err(1, "Read failure on file |%s|", path);
  }

  close(target_file);

  file_contents[file_pos] = '\0';
  return file_contents;
}

/* The only place that calls this function currently doesn't care whether the
 * write succeeds or not. This should be changed to report success or failure
 * if that becomes important in the future. */
static void write_text_file(const char *cont_dir, const char *path,
  const char *text, bool do_flock) {
  struct stat stinfo             = { 0 };
  int         target_file        = 0;
  size_t      remaining_text_len = 0;
  ssize_t     write_bytes        = 0;

  if (stat(cont_dir, &stinfo) == -1) {
    if (errno != ENOENT) {
      warn("Could not stat path |%s|", cont_dir);
      return;
    }

    if (mkdir(cont_dir, 0755) == -1) {
      warn("Directory |%s| does not exist and cannot be created", cont_dir);
      return;
    }

    /* If we get here, the directory was successfully created, the following
     * else condition is skipped, and the rest of the function runs. */
  } else {
    if (!S_ISDIR(stinfo.st_mode)) {
      warnx("Path |%s| is not a directory\n", cont_dir);
      return;
    }
  }

  target_file = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (target_file == -1) {
    warn("Could not open file |%s| for writing", path);
    return;
  }

  if (do_flock) {
    flock_exclusive_safe(target_file, path);
  }

  remaining_text_len = strlen(text);

  while ((write_bytes = write(target_file, text, remaining_text_len)) > 0) {
    remaining_text_len -= write_bytes;
  }
  if (write_bytes < 0) {
    err(1, "Write failure on file |%s|", path);
  }

  close(target_file);
}

static void conf_file_line_trim(char **file_line_ref) {
  char  *file_line     = NULL;
  size_t file_line_len = 0;

  file_line     = *file_line_ref;
  file_line_len = strlen(file_line);

  /* Advance the pointer past leading whitespace */
  while (file_line[0] == ' ') {
    file_line++;
    file_line_len--;
  }

  /* Trim off any comment */
  for (size_t i = 0; i < file_line_len; i++) {
    if (file_line[i] == '#') {
      file_line[i]  = '\0';
      file_line_len = i;
      break;
    }
  }

  /* Trim off any trailing whitespace */
  for (ssize_t i = file_line_len - 1; i >= 0; i--) {
    if (file_line[i] == ' ') {
      file_line[i] = '\0';
    } else {
      break;
    }
  }

  *file_line_ref = file_line;
}

static void parse_fan_profile_db(void) {
  char         *orig_file_ptr           = NULL;
  char         *file_ptr                = NULL;
  char         *file_line               = NULL;
  char         *temperature_str         = NULL;
  char         *parse_str_endptr        = NULL;
  ssize_t       header_idx              = -1;
  int16_t       last_temperature_val    = -1;
  bool          valid_header_found      = false;
  bool          fanauto_marker_found    = false;
  bool          speed_config_found      = false;
  unsigned long current_temperature_val = 0;
  char         *speed_str_list[MAX_FAN_COUNT];
  uint8_t       last_speed_val_list[MAX_FAN_COUNT];
  unsigned long current_speed_val_list[MAX_FAN_COUNT];

  for (size_t i = 0; i < FAN_PROFILE_COUNT; i++) {
    for (size_t j = 0; j < MAX_FAN_COUNT; j++) {
      for (size_t k = 0; k < 256; k++) {
        fan_profile_data[i][j][k] = -1;
      }
    }
  }
  memset(fan_profile_present_list, 0, FAN_PROFILE_COUNT * sizeof(bool));
  memset(current_speed_val_list,   0, MAX_FAN_COUNT     * sizeof(
    unsigned long));

  orig_file_ptr = file_ptr = read_text_file(FAN_PROFILE_DB_PATH, false);
  if (file_ptr == NULL) {
    exit(1);
  }

  /* Parse the file and populate the profile arrays with info from it */
  while ((file_line = strsep(&file_ptr, "\n")) != NULL) {
    conf_file_line_trim(&file_line);

    if (strcmp(file_line, "") == 0) {
      continue;
    }

    for (size_t i = 0; i < FAN_PROFILE_COUNT; i++) {
      if (strcmp(file_line, fan_profile_header_list[i]) == 0) {
        if (fan_profile_present_list[i]) {
          errx(1, "Duplicate header |%s| in fan profile db file\n", file_line);
        }
        fan_profile_present_list[i] = true;
        valid_header_found          = true;
        header_idx                  = i;
        temperature_str             = NULL;
        last_temperature_val        = -1;
        current_temperature_val     = 0;
        fanauto_marker_found        = false;
        speed_config_found          = false;
        memset(speed_str_list,         0, MAX_FAN_COUNT * sizeof(char *));
        memset(last_speed_val_list,    0, MAX_FAN_COUNT * sizeof(uint8_t));
        memset(current_speed_val_list, 0, MAX_FAN_COUNT * sizeof(
          unsigned long));
        break;
      }
    }

    /* We tested if file_line is an empty string already, so file_line[0] must
     * exist. */
    if (file_line[0] == '=') {
      if (!valid_header_found) {
        errx(1, "Invalid header |%s| in fan profile db file\n", file_line);
      }
      valid_header_found = false; /* reset for next time we find a header */
      continue;
    }

    if (strcmp(file_line, "FANAUTO") == 0) {
      if (speed_config_found) {
        errx(1, "FANAUTO line found after profile speed config\n");
      }
      fanauto_marker_found = true;
      fan_profile_present_list[header_idx] = false;
      continue;
    }

    if (fanauto_marker_found) {
      errx(1, "Profile speed config found after a FANAUTO line\n");
    }

    if (header_idx == -1) {
      errx(1, "Non header line |%s| found before any header\n", file_line);
    }

    speed_config_found = true;

    for (size_t i = 0; i < MAX_FAN_COUNT + 1; i++) {
      char *bit_str = strsep(&file_line, ":");
      if (i == 0) {
        temperature_str = bit_str;
      } else {
        speed_str_list[i - 1] = bit_str;
      }
    }

    if ( speed_str_list[0] == NULL || speed_str_list[0][0] == '\0'
      || temperature_str   == NULL || temperature_str[0]   == '\0'
      || file_line         != NULL) {
      errx(1, "Malformed profile line\n");
    }
    for (size_t i = 1; i < MAX_FAN_COUNT; i++) {
      if (speed_str_list[i] != NULL && speed_str_list[i][0] == '\0') {
        errx(1, "Malformed profile line (blank speed value)\n");
      }
    }

    current_temperature_val = strtoul(temperature_str, &parse_str_endptr, 10);
    if (*parse_str_endptr != '\0') {
      errx(1, "Invalid temperature string\n");
    }
    if (current_temperature_val > 255) {
      errx(1, "Out-of-range temperature value (max is 255)\n");
    }
    if ((int16_t)(current_temperature_val) <= last_temperature_val) {
      errx(1, "Used or skipped temperature value found later\n");
    }
    last_temperature_val = current_temperature_val;

    for (size_t i = 0; i < MAX_FAN_COUNT; i++) {
      if (speed_str_list[i] == NULL) {
        assert(i != 0);
        current_speed_val_list[i] = current_speed_val_list[i - 1];
      } else {
        current_speed_val_list[i] = strtoul(speed_str_list[i],
          &parse_str_endptr, 10);
        if (*parse_str_endptr != '\0') {
          errx(1, "Empty speed string\n");
        }
      }
      if (current_speed_val_list[i] > 255) {
        errx(1, "Out-of-range speed value (max is 255)\n");
      }
      if (current_speed_val_list[i] < last_speed_val_list[i]) {
        errx(1, "Skipped speed value found later\n");
      }
      last_speed_val_list[i] = current_speed_val_list[i];
      fan_profile_data[header_idx][i][current_temperature_val]
        = current_speed_val_list[i];
    }
  }

  free(orig_file_ptr);

  /* Replace all -1's in the profile list with values rounded up to the next
   * highest configured value. If the high end of the profile list contains
   * -1s, replace those with 255. */
  for (size_t i = 0; i < FAN_PROFILE_COUNT; i++) {
    if (!fan_profile_present_list[i]) {
      continue;
    }
    for (size_t j = 0; j < MAX_FAN_COUNT; j++) {
      int16_t set_val = 255;

      for (ssize_t k = 255; k >= 0; k--) {
        if (fan_profile_data[i][j][k] == -1) {
          fan_profile_data[i][j][k] = set_val;
        } else {
          set_val = fan_profile_data[i][j][k];
        }
      }
    }
  }
}

static void determine_active_fan_profile(void) {
  char *profile_ptr      = NULL;
  char *orig_profile_ptr = NULL;
  char *line_one         = NULL;

  fan_profile_idx = -1;
  orig_profile_ptr = profile_ptr = read_text_file(FAN_CONFIG_PATH, true);
  if (profile_ptr == NULL || profile_ptr[0] == '\0'
    || profile_ptr[0] == '\n') {
    /* No fan profile found, use the "balanced" mode by default and write the
     * fan config file */
    for (size_t i = 0; i < FAN_PROFILE_COUNT; i++) {
      if (strcmp(fan_profile_header_list[i], "=balanced") == 0) {
        fan_profile_idx = i;
        break;
      }
    }
    write_text_file(STATE_DIR_PATH, FAN_CONFIG_PATH, "balanced\n", true);
    return;
  }

  line_one = strsep(&profile_ptr, "\n");

  for (size_t i = 0; i < FAN_PROFILE_COUNT; i++) {
    if (strcmp(line_one, fan_profile_header_list[i] + 1) == 0) {
      fan_profile_idx = i;
      break;
    }
  }

  if (fan_profile_idx == -1) {
    errx(1, "File |%s| contained invalid profile name |%s|\n", FAN_CONFIG_PATH, line_one);
  }
  free(orig_profile_ptr);
}

static void set_fan_automatic_mode(bool can_exit) {
  int     ioctl_rslt = 0;
  int32_t fan_arg    = 0x0F;

  ioctl_rslt = ioctl(driver_handle, W_CL_FANAUTO, &fan_arg);
  if(ioctl_rslt == -1) {
    if (can_exit) {
      err(1, "Cannot set fan to automatic mode");
    } else {
      /* atexit handler, we cannot use err() here, and the program is
       * terminating anyway so there's no need to use err() */
      warn("Cannot set fan to automatic mode");
    }
  }
}

/* Do NOT call this function directly, it is called via an atexit handler. */
static void exit_cleanup(void) {
  set_fan_automatic_mode(false);
}

/* Note that this is NOT a true UNIX signal handler; it is called by
 * main_loop() to read a signalfd_siginfo struct from signal_handle and do
 * something with it. Thus we can call non-async-signal-safe functions
 * here. */
void handle_signal(void) {
  ssize_t                 read_rslt       = 0;
  struct signalfd_siginfo signal_info     = { 0 };
  struct timespec         ts              = { 0 };
  uint64_t                current_time_ms = 0;

  while ((read_rslt = read(signal_handle, &signal_info,
    sizeof(struct signalfd_siginfo))) == 0) {
    continue;
  }
  if (read_rslt == -1) {
    err(1, "Could not read from signal fd");
  }

  switch(signal_info.ssi_signo) {
  case SIGUSR1:
    /* reload config */
    clock_gettime(CLOCK_MONOTONIC, &ts);
    current_time_ms = (uint64_t)((ts.tv_sec * 1000000) + (ts.tv_nsec / 1000));
    sd_notifyf(0, "RELOADING=1\nMONOTONIC_USEC=%ld", current_time_ms);
    parse_fan_profile_db();
    determine_active_fan_profile();

    if (fan_profile_idx == -1 || !fan_profile_present_list[fan_profile_idx]) {
      /* Put the daemon into a dormant mode */
      set_fan_automatic_mode(true);
      for (size_t i = 0; i < MAX_FAN_COUNT; i++) {
        active_fan_speed_list[i] = -1;
      }
    }
    sd_notify(0, "READY=1");
    return;
  case SIGWINCH:
  case SIGTTIN:
  case SIGTTOU:
  case SIGCONT: /* systemd sends us this during a reload */
    /* ignore */
    return;
  }

  /* terminate */
  exit(128 + signal_info.ssi_signo);
}

void main_loop(void) {
  int      poll_rslt        = 0;
  int      ioctl_rslt       = 0;
  uint32_t fan_info_val     = 0;
  uint8_t  fan_temp         = 0;
  uint8_t  fan_speed        = 0;
  uint8_t  watchdog_counter = 0;

  while (true) {
    bool write_fan_speeds = false;

    poll_rslt = poll(&poll_watch, 1, POLL_WAIT_MS);
    if (poll_rslt == -1) {
      err(1, "Poll failed");
    }

    if (poll_rslt != 0) {
      watchdog_counter = 0;
      sd_notify(0, "WATCHDOG=1");
      handle_signal();
      continue;
    }

    watchdog_counter++;
    if (watchdog_counter == WATCHDOG_INTERVAL_SEC) {
      watchdog_counter = 0;
      sd_notify(0, "WATCHDOG=1");
    }

    if (fan_profile_idx == -1 || !fan_profile_present_list[fan_profile_idx]) {
      continue;
    }

    for (size_t i = 0; i < MAX_FAN_COUNT; i++) {
      switch(i) {
      case 0:
        ioctl_rslt = ioctl(driver_handle, R_CL_FANINFO1, &fan_info_val);
        break;
      case 1:
        ioctl_rslt = ioctl(driver_handle, R_CL_FANINFO2, &fan_info_val);
        break;
      case 2:
        ioctl_rslt = ioctl(driver_handle, R_CL_FANINFO3, &fan_info_val);
        break;
      default:
        errx(1, "No read ioctl for fan value\n");
      }

      if (ioctl_rslt == -1) {
        err(1, "Cannot get fan %ld speed", i + 1);
      }

      /* Fan temp degrees C is in the third byte of fan_info_val */
      fan_temp = (fan_info_val >> 16) & 0xff;
      fan_speed = fan_profile_data[fan_profile_idx][i][fan_temp];
      if (fan_speed != active_fan_speed_list[i]) {
        write_fan_speeds = true;
        active_fan_speed_list[i] = fan_speed;
      }
    }

    if (write_fan_speeds) {
      int32_t fan_arg = (uint8_t)(active_fan_speed_list[0]);
      fan_arg        |= (uint8_t)(active_fan_speed_list[1]) << 8;
      fan_arg        |= (uint8_t)(active_fan_speed_list[2]) << 16;

      ioctl_rslt = ioctl(driver_handle, W_CL_FANSPEED, &fan_arg);
      if (ioctl_rslt == -1) {
        err(1, "Cannot set fan speeds");
      }
    }
  }
}

int main(void) {
  sigset_t all_signals;

  driver_handle = open(CONTROL_DEV_PATH, O_RDWR);
  if (driver_handle == -1) {
    err(1, "Unable to open driver interface");
  }

  for (size_t i = 0; i < MAX_FAN_COUNT; i++) {
    active_fan_speed_list[i] = -1;
  }
  set_fan_automatic_mode(true);

  parse_fan_profile_db();
  determine_active_fan_profile();

  /* debugging
  for (size_t i = 0; i < FAN_PROFILE_COUNT; i++) {
    if (!fan_profile_present_list[i]) {
      printf("Fan profile %s missing\n", fan_profile_header_list[i] + 1);
      continue;
    }
    for (size_t j = 0; j < MAX_FAN_COUNT; j++) {
      for (size_t k = 0; k < 256; k++) {
        printf("Fan profile %s: fan %ld, temperature %ld, speed %d\n",
          fan_profile_header_list[i] + 1,
          j, k, fan_profile_data[i][j][k]);
      }
    }
  }
  exit(0);
  */

  if (atexit(exit_cleanup) != 0) {
    errx(1, "Unable to register exit cleanup function\n");
  }

  sigfillset(&all_signals);
  if (sigprocmask(SIG_SETMASK, &all_signals, NULL) == -1) {
    err(1, "Unable to block signals");
  }
  signal_handle = signalfd(-1, &all_signals, 0);
  if (signal_handle == -1) {
    err(1, "Could not set up signal fd");
  }
  poll_watch.fd = signal_handle;
  poll_watch.events = POLLIN;

  sd_notify(0, "READY=1");
  sd_notify(0, "WATCHDOG=1");
  main_loop();
}
