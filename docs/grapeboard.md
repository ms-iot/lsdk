Building for Grapeboard
============

This document will walk you through building all components from source for [Scalys Grapeboard](https://www.grapeboard.com/). The components we will build are
 - RCW and PBI script
 - U-Boot
 - PPA (Primary Protected Application)
 - OP-TEE
 - Linux

# Booting Grapeboard into recovery mode

See section 5.3 of the [Grapeboard BSP User Guide](https://www.grapeboard.com/wp-content/uploads/2018/05/scalys_grapeboard_bsp_user_guide_180518.pdf).

1. Connect the Grapeboard to your host PC and open a serial terminal at 115200 8N1. If you're using Putty on Windows, you must go to **Connection -> Serial** and set **Flow control** to **None**.
![Putty Flow Control](putty-flow-control.png)
1. Press and hold switch `S2` on the Grapeboard.
1. Power-up (or reset with switch `S1`) the Grapeboard
1. Release switch `S2` once U-boot prints the message: `Please release the rescue mode button (S2) to enter the recovery mode`

You can then issue U-Boot commands to update the main NOR flash with new firmware images.

# Building RCW and PBI Script

Todo.

# Building U-Boot

Todo.

# Building PPA and OPTEE

```
flex-builder -c ppa-optee -m ls1012grapeboard
```

It will produce the file `build/firmware/ppa/soc-ls1012/ppa_rdb.itb`.

Copy `ppa_rdb.itb` to the root of a FAT-formatted SD card.

Boot into [recovery U-Boot](#Booting-Grapeboard-into-recovery-mode), then run the following u-boot commands:

```
mmc rescan
fatload mmc 0:1 $load_addr ppa_rdb.itb
sf probe 0:0
sf erase ppa 100000
sf write $load_addr ppa $filesize
```

Reset the board. When it reboots, you should see output like the following, which indicates that you successfully updated the PPA and OPTEE.

```
PPA Firmware: Version LSDK-18.09-dirty
SEC Firmware: 'loadables' present in config
loadables: 'trustedOS@1'
```
