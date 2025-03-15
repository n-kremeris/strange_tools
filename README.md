# strange_tools

# **`transfer_by_typing.sh`**

This is a WIP tool dumps a hex string of any file and then transfers it to a remote machine by typing it out into the target window terminal. It is useful if you ever find yourself in some insane circumstances, like having a dracut, initramfs or other type of extremely limited recovery shell, and no other way to access the machine or transfer anything to it. 
You can use this to copy small executable tools or any other files over to the target machine, all you need is a window with a terminal open.

I wrote it to copy over a kernel driver module into a dracut recovery shell that was needed to mount the rootfs. The driver was missing inside the generated initramfs due to an oversight, and there was no backup initramfs in /boot, and no other access to the machine other than an extremely limited cloud IPMI shell via a web browser.
