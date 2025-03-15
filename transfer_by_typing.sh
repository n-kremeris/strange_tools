#!/bin/bash

# This tool dumps a hex string of any file and then transfers it to a remote 
# machine by typing it out into the target window terminal. It is useful
# if you ever find yourself in some insane circumstances, like having a dracut,
# initramfs or other type of extremely limited recovery shell, and no other
# way to access the machine or transfer anything to it.
#
# You can use this to copy small executable tools or any other files over to
# the target machine, all you need is a window with a terminal open.
#
# I personally used it to copy over a kernel driver module into a dracut
# recovery shell that was needed to mount the rootfs but was missing inside
# the generated initramfs due to an oversight, with no backup being available
# in /boot and no other access to the machine other than an extremely limited
# cloud IPMI shell via a web browser (shell-in-a-box)

# PREREQUISITES
# 1. a graphical environment
# 2. xdotool

# HOW TO USE
# 1. Copy the file you want to transfer into the same working dir as this script
#
# 2. Set the FILE variable to match the name of the file you want to copy
#
# 3. Launch the script ./transfer_by_typing.sh and place your mouse on top of the target window
#
# 4. Wait for transfer to finish
#
# 5. When done, check the target terminal for "TRANSFER SUCCESS" or "TRANSFER FAIL" messages.
#    The success is checked by comparing the md5sum of sent and received files.
#    NOTE: disable md5sum code if md5sum not available in target environment.
#   
# 6. In case of issues, try sending a smaller file and adjust TYPING_DELAY,
#    SIGNAL_DELAY and CHUNKSIZE until it succeeds

# OTHER INFO
# 1. Transfering Executables - if your limited environment has no chmod, you can 
#    skip marking the transfered binary as executable by launching it via the dynamic
#    loader directly, e.g.: /lib/ld-linux-x86-64.so.2 ./binary
# 2. Why dumping hex instead of base64? - i didn't have base64 on the target.
# 3. Why no compression? - i didn't have any compression tools on the target.


# Filename to transfer, must be in local folder for now
FILE=binary

# Delay between typing regular characters
TYPING_DELAY=1 #in miliseconds
# Delay after 
SIGNAL_DELAY=0.4 #in seconds

# Defines how many hex characters to send at once, hard limit is 4095 
# (See here for more info: https://unix.stackexchange.com/questions/643777/is-there-any-limit-on-line-length-when-pasting-to-a-terminal-in-linux)
# (Transferring in chunks was chosen due to "stty" not available in my target environment (dracut))
# If your target terminal crashes during transfer, try to reduce this number
CHUNKSIZE=3000

echo "Sending file $FILE"

#chunksize must be rounded to nearest 2
round_to_nearest_2() {
    local num=$1
    echo $(( (num + 1) / 2 * 2 ))
}
echo "Original CHUNKSIZE: $CHUNKSIZE"
CHUNKSIZE=$(round_to_nearest_2 "$CHUNKSIZE")
echo "Corrected CHUNKSIZE: $CHUNKSIZE"

# convert binary to hex dump
hexdump -v -e '1/1 "%02x"' $FILE | cat > hexdump

alias xdotool="xdotool --delay $TYPING_DELAY"

echo PLACE CURSOR ON TRANSFER WINDOW
echo SLEEPING FOR 5 SECONDS
sleep 5

xdotool key Return
sleep $SIGNAL_DELAY
xdotool key ctrl+c
sleep $SIGNAL_DELAY
xdotool type "rm -rf $FILE"
xdotool key Return
sleep $SIGNAL_DELAY

# disable wraparound in terminal - allows faster transfers and less lag
# when target is shell-in-a-box
xdotool type "echo -ne '\\e[?7l'"
xdotool key Return
sleep $SIGNAL_DELAY

# read hexdump in chunks and type it out on the target window
while IFS= read -r -n "$CHUNKSIZE" CHUNK || [[ -n "$CHUNK" ]]; do
    echo "SENDING: $CHUNK"
    #sed transforms the hexdump into shellcode, e.g. "00aaffbb" -> "\x00\xa\xff\xbb"
    xdotool type "printf \"\$(echo -n \"$CHUNK\" | sed 's/\(..\)/\\\\x\1/g')\" >> $FILE"
    xdotool key Return
    sleep $SIGNAL_DELAY
done < hexdump

# re-enable wraparound
xdotool type "echo -ne '\\e[?7h'"
xdotool key Return
sleep $SIGNAL_DELAY

# check md5sum of transfered file against the source
SUM=$(md5sum $FILE | awk '{ print $1 }')
xdotool type "[ \"$SUM\" = \"\$(md5sum $FILE | awk '{ print \$1 }')\" ] && echo \"TRANSFER SUCCESS\" || echo \"TRANFER FAIL\""
xdotool key Return
