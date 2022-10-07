#!/bin/sh

/sbin/write_log "[VM-TEST-01 AUTOSTART] Starting up VM-TEST-01 Machine" 4

# Find where script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Wait until virsh is available

OUTPUT="$(/QVS/usr/bin/virsh quit)"

while [[ $OUTPUT == *"command not found"* ]]
do

/sbin/write_log "[VM-TEST-01 AUTOSTART] Virsh command not found, waiting" 4

OUTPUT="$(/QVS/usr/bin/virsh quit)"

sleep 10

done

# First start and resume VM-TEST-01 machine

/QVS/usr/bin/virsh start c29a6780-0494-4de3-89ea-8120fc01a22f
/QVS/usr/bin/virsh resume c29a6780-0494-4de3-89ea-8120fc01a22f

# Wait 10 sec

sleep 10

# Discover relevant USB devices and write xml files

# How many numbers are returned per lsusb device listing
POINTS_PER_DEVICE=6
# Command to grep for USB devices from vendor Cygnal
DEVICES=$(lsusb | grep Cygnal)
# Trimming all numbers out
NUMBERS=$( echo "$DEVICES" | sed -e 's/[^0-9]/ /g' | tr -s ' ')

ARRAY=()
NUMBER=0
for num in $NUMBERS; do
   NUMBER=$((NUMBER + 1));
   #echo "number: $NUMBER value: $((10#$num))"
   ARRAY[$NUMBER]=$((10#$num));
done

NUM_DEVICES=$(( NUMBER / POINTS_PER_DEVICE ));
echo "Found $NUM_DEVICES devices matching."

for (( devices=1; devices <= $NUM_DEVICES; devices++ )); do
   INDEX=$(( devices * POINTS_PER_DEVICE - POINTS_PER_DEVICE + 1));
   echo "<hostdev mode='subsystem' type='usb'>
         <source startupPolicy='optional'>
         <address bus='${ARRAY[$INDEX]}' device='${ARRAY[$INDEX + 1]}'/>
         </source>
         </hostdev>" > $DIR/Automount_${devices}_usb.xml
   echo "Created Automount_${devices}_usb.xml file."
   # Then mount USB
   /QVS/usr/bin/virsh attach-device c29a6780-0494-4de3-89ea-8120fc01a22f $DIR/Automount_${devices}_usb.xml
done

# Start VM-TEST-01 another time, to be sure

/QVS/usr/bin/virsh start c29a6780-0494-4de3-89ea-8120fc01a22f

/sbin/write_log "[VM-TEST-01 AUTOSTART] Autostart of VM-TEST-01 Machine Completed" 4

