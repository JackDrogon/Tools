#!/usr/bin/env bash

disk=$1
echo 0 | sudo tee /sys/fs/bcache/${disk}/bdev0/writeback_percent
