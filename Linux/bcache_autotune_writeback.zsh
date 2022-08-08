#!/usr/bin/env zsh

K=1024
M=$((1024 * $K))
G=$((1024 * $M))
LOWWATER_SIZE=$((45 * $M)) # 45M
HIGHWATER_SIZE=$((61 * $G)) # 61G
WRITEBACK_PERCENT=7 # 830 * 7% = 58.66

get_device_data_size() {
	local device_num=$1
	local dirty_data="$(cat /sys/block/bcache$device_num/bcache/dirty_data)"
	local dirty_data_num=${dirty_data:0:-1}

	case $dirty_data in
		*T)
			echo $(($dirty_data_num * 1024 * 1024 * 1024 * 1024))
			;;
		*G)
			echo $(($dirty_data_num * 1024 * 1024 * 1024))
			;;
		*M)
			echo $(($dirty_data_num * 1024 * 1024))
			;;
		*k)
			echo $(($dirty_data_num * 1024))
			;;
		*)
			echo $dirty_data
			;;
	esac
}

device::get_writeback_percent() {
	local device_num=$1
	cat "/sys/block/bcache${device_num}/bcache/writeback_percent"
}

device::set_writeback_percent() {
	local device_num=$1
	local writeback_percent=$2
	echo "${writeback_percent}" > "/sys/block/bcache${device_num}/bcache/writeback_percent"
}

device::check() {
	local device_num=$1
	local data_size=$(get_device_data_size $device_num)
	echo $data_size

	local current_writeback_percent=$(device::get_writeback_percent ${device_num})

	if [[ $data_size -ge $HIGHWATER_SIZE ]]; then
		echo $data_size $HIGHWATER_SIZE
		date; echo HighWater
		echo

		if [[ $current_writeback_percent = 0 ]]; then
			return
		fi

		echo 0 > /sys/block/bcache${device_num}/bcache/writeback_percent
	elif [[ $data_size -le $LOWWATER_SIZE ]]; then
		date; echo LowWater
		echo

		if [[ $current_writeback_percent != 0 ]]; then
			return
		fi

		device::set_writeback_percent "${device_num}" "${WRITEBACK_PERCENT}"
	else
		date;
		if [[ $current_writeback_percent = 0 ]]; then
			echo "Reduce"
		else
			echo "Grow"
		fi
		echo
	fi
}

main() {
	while true; do
		for device_num in `seq 0 4`; do
			device::check $device_num
		done
		sleep 45
	done
}


main
