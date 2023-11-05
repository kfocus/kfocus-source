#!/bin/bash
set -e
apt-get -y --fix-broken remove;
ppa-purge ppa:kfocus-team/release;
apt-get -y install linux-generic-hwe-22.04 \
  linux-headers-generic-hwe-22.04 \
  linux-image-generic-hwe-22.04 \
  linux-tools-generic-hwe-22.04;
