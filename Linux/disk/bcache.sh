#!/usr/bin/env bash

  # echo 0 | sudo tee /sys/block/bcache4/bcache/writeback_percent
percent=${1:-10}
echo "writeback_percent: $percent"

for i in `seq 0 4`; do
	origin=$(cat /sys/block/bcache$i/bcache/writeback_percent)
	echo -n "bcache$i :   ${origin} => "
	echo $percent | sudo tee /sys/block/bcache$i/bcache/writeback_percent
done
