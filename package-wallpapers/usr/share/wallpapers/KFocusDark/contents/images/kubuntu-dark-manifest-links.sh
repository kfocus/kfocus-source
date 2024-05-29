#!/bin/bash

_checkFileFn () {
  if ! [ -f "$1" ]; then
    echo "Missing required file $1";
    exit 1;
  fi
  _size1_str="$(cut -f1 -d'.' <<< "$1")";
  _size2_str="$(cut -f3 -d' ' <<< "$(identify "$1")")";
  if [ "${_size1_str}" != "${_size2_str}" ]; then
    echo "Expected size not found";
    echo "${_size1_str} != ${_size2_str}";
    exit 2;
  fi
}

# 1:2
_checkFileFn '1920x3840.png';
rm -f 360x720.png;
rm -f 720x1440.png;
ln -s 1920x3840.png 360x720.png;
ln -s 1920x3840.png 720x1440.png;

# 9:16
_checkFileFn '2160x3840.png';
rm -f 1080x1920.png;
ln -s 2160x3840.png 1080x1920.png

# 10:16
_checkFileFn '2400x3840.png';
rm -f 1200x1920.png;
ln -s 2400x3840.png 1200x1920.png

# 5:4
_checkFileFn '3000x2400.png';
rm -f 1024x768.png;
rm -f 1280x1024.png;
ln -s 3000x2400.png 1024x768.png
ln -s 3000x2400.png 1280x1024.png

# 16:9
_checkFileFn '3840x2160.png';
_checkFileFn '5120x2880.png';
rm -f 440x247.png;
rm -f 640x360.png;
rm -f 1024x576.png;
rm -f 1280x720.png;
rm -f 1366x768.png;
rm -f 1600x900.png;
rm -f 1680x945.png;
rm -f 1920x1080.png;
rm -f 2560x1440.png;
rm -f 3200x1800.png;
ln -s 3840x2160.png 440x247.png
ln -s 3840x2160.png 640x360.png
ln -s 3840x2160.png 1024x576.png
ln -s 3840x2160.png 1280x720.png
ln -s 3840x2160.png 1366x768.png
ln -s 3840x2160.png 1600x900.png
ln -s 3840x2160.png 1680x945.png
ln -s 3840x2160.png 1920x1080.png
ln -s 3840x2160.png 2560x1440.png
ln -s 3840x2160.png 3200x1800.png

# 16:10
_checkFileFn '3840x2400.png';
_checkFileFn '5120x3200.png';
rm -f 640x400.png;
rm -f 1280x800.png;
rm -f 1440x900.png;
rm -f 1680x1050.png;
rm -f 1920x1200.png;
rm -f 2560x1600.png;
rm -f 3200x2000.png;
ln -s 3840x2400.png 640x400.png
ln -s 3840x2400.png 1280x800.png
ln -s 3840x2400.png 1440x900.png
ln -s 3840x2400.png 1680x1050.png
ln -s 3840x2400.png 1920x1200.png
ln -s 3840x2400.png 2560x1600.png
ln -s 3840x2400.png 3200x2000.png

# 16:12 (4:3)
_checkFileFn '3200x2400.png';
rm -f 1600x1200.png;
ln -s 3200x2400.png 1600x1200.png

