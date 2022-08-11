#!/usr/bin/env zsh

K=1024
M=$((1024 * $K))
G=$((1024 * $M))
T=$((1024 * $G))

LOWWATER_SIZE=$((45 * $M)) # 45M
HIGHWATER_SIZE=$((61 * $G)) # 61G
WRITEBACK_PERCENT=7 # 830 * 7% = 58.66
DEVICE_NUM=4
WRITE_MAGNIFICATION=3
TIGGER_GC_SLEEP_TIME=15

device::_get_data_size() {
	local device_num=$1

	local dirty_data="$(cat /sys/block/bcache$device_num/bcache/dirty_data)"
	local dirty_data_num=${dirty_data:0:-1}

	case $dirty_data in
		*T)
			echo $(($dirty_data_num * $T))
			;;
		*G)
			echo $(($dirty_data_num * $G))
			;;
		*M)
			echo $(($dirty_data_num * $M))
			;;
		*k)
			echo $(($dirty_data_num * $K))
			;;
		*)
			echo $dirty_data
			;;
	esac
}

device::_get_cache_available_percent() {
	local device_num=$1

	cat "/sys/block/bcache${device_num}/bcache/cache/cache_available_percent"
}

device::_get_writeback_percent() {
	local device_num=$1

	cat "/sys/block/bcache${device_num}/bcache/writeback_percent"
}

device::_set_writeback_percent() {
	local device_num=$1
	local writeback_percent=$2

	echo "${writeback_percent}" > "/sys/block/bcache${device_num}/bcache/writeback_percent"
}

device::handle_highwater() {
	local device_num=$1

	local current_writeback_percent=$(device::_get_writeback_percent ${device_num})
	if [[ $current_writeback_percent = 0 ]]; then
		return
	fi

	device::_set_writeback_percent "${device_num}" 0
}

device::_maybe_trigger_bcache_gc() {
	# lowwater && current_cache_available_percent low
	# lowwater guaranteed by caller
	local device_num=$1

	local current_cache_available_percent=$(device::_get_cache_available_percent ${device_num})
	if [[ $current_cache_available_percent -le $((100 - $WRITEBACK_PERCENT * $WRITE_MAGNIFICATION)) ]]; then
		echo "Cache available percent so small: ${current_cache_available_percent}, trigger_gc"
		echo

		echo 1 > /sys/block/bcache${device_num}/bcache/cache/internal/trigger_gc
		sleep "${TIGGER_GC_SLEEP_TIME}" # Add sleep for bcache do gc work
	fi
}

device::handle_lowwater() {
	local device_num=$1

	local current_writeback_percent=$(device::_get_writeback_percent ${device_num})
	if [[ $current_writeback_percent != 0 ]]; then
		device::_maybe_trigger_bcache_gc "${device_num}"
		return
	fi

	device::_set_writeback_percent "${device_num}" "${WRITEBACK_PERCENT}"
}

device::handle_custom() {
	local device_num=$1

	local current_writeback_percent=$(device::_get_writeback_percent ${device_num})
	if [[ $current_writeback_percent = 0 ]]; then
		echo "Reduce"
		echo
		return
	fi

	local current_cache_available_percent=$(device::_get_cache_available_percent ${device_num})
	if [[ $current_cache_available_percent -le $((100 - $WRITEBACK_PERCENT*3)) ]]; then
		echo "Cache available percent so small: ${current_cache_available_percent}"
		echo

		device::_set_writeback_percent "${device_num}" 0
	else
		echo "Grow"
		echo
	fi
}

device::check() {
	local device_num=$1

	local data_size=$(device::_get_data_size $device_num)

	echo $data_size

	if [[ $data_size -ge $HIGHWATER_SIZE ]]; then
		echo $data_size $HIGHWATER_SIZE
		date; echo HighWater
		echo

		device::handle_highwater "${device_num}"
	elif [[ $data_size -le $LOWWATER_SIZE ]]; then
		date; echo LowWater
		echo

		device::handle_lowwater "${device_num}"
	else
		date;

		device::handle_custom "${device_num}"
	fi
}

main() {
	while true; do
		for device_num in $(seq 0 ${DEVICE_NUM}); do
			device::check $device_num
		done
		sleep 45
	done
}
main
