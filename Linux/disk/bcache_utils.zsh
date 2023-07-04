#!/usr/bin/env zsh

function bcache::_get_device() {
	addr=$1
	device_block_num=$(cat "$addr")
	device=$(readlink "/dev/block/${device_block_num}" | cut -d/ -f2)
	echo $device
}

function bcache::get_backend_device() {
	local device_num=$1
	local backend_device=$(bcache::_get_device "/sys/block/bcache${device_num}/bcache/cache/bdev0/../dev")
	echo ${backend_device}
}

function bcache::get_cache_device() {
	local device_num=$1
	local cache_device=$(bcache::_get_device "/sys/block/bcache${device_num}/bcache/cache/cache0/../dev")
	echo ${cache_device}
}

# get all bcache device nums
function bcache::get_device_nums() {
	local device_nums=$(ls /sys/block | grep bcache | sed 's/bcache//')
	echo ${device_nums}
}