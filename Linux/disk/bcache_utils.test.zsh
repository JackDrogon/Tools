#!/usr/bin/env zsh

source ./bcache_utils.zsh

# Test bcache::get_device_nums
echo "Testing bcache::get_device_nums..."
device_nums=$(bcache::get_device_nums)
expected_device_nums="0
1
2
3
4"
if [[ "$device_nums" == "$expected_device_nums" ]]; then
  echo "PASS"
else
  echo "FAIL: expected $expected_device_nums but got $device_nums"
fi

# Test bcache::get_backend_device
echo "Testing bcache::get_backend_device..."
backend_device=$(bcache::get_backend_device 0)
expected_backend_device="sd*"
if [[ "$backend_device" =~ "$expected_backend_device" ]]; then
  echo "PASS"
else
  echo "FAIL: expected $expected_backend_device but got $backend_device"
fi

# Test bcache::get_cache_device
echo "Testing bcache::get_cache_device..."
cache_device=$(bcache::get_cache_device 0)
expected_cache_device="nvme*"
if [[ "$cache_device" =~ "$expected_cache_device" ]]; then
  echo "PASS"
else
  echo "FAIL: expected $expected_cache_device but got $cache_device"
fi