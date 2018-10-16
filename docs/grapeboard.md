Building for Grapeboard
============

This document will walk you through building all components from source for [Scalys Grapeboard](https://www.grapeboard.com/). The components we will build are
 - RCW and PBI script
 - U-Boot
 - PPA (Primary Protected Application)
 - OP-TEE
 - Linux

# Building RCW and PBI Script

Todo.

# Building U-Boot

Todo.

# Building PPA and OP-TEE

```
flex-builder -c ppa-optee -m ls1012grapeboard
```

It will produce the file `build/firmware/ppa/soc-ls1012/ppa_rdb.itb`. This file must be written to NOR flash.

## Updating PPA and OP-TEE on NOR Flash

Copy `ppa_rdb.itb` to the root of a FAT-formatted SD card.

Boot into [recovery U-Boot](#booting-grapeboard-into-recovery-mode), then run the following u-boot commands:

```
mmc rescan
fatload mmc 0:1 $load_addr ppa_rdb.itb
sf probe 0:0
sf erase ppa 100000
sf write $load_addr ppa $filesize
```

Reset the board. When it reboots, you should see output like the following, which indicates that you successfully updated PPA and OP-TEE.

```
PPA Firmware: Version LSDK-18.09-dirty
SEC Firmware: 'loadables' present in config
loadables: 'trustedOS@1'
```

# Building Linux

```
flex-builder -c linux -a arm64 -m ls1012grapeboard
flex-builder -i mkrfs -a arm64
flex-builder -i mkbootpartition -m ls1012grapeboard -a arm64
flex-builder -c optee_client -a arm64
flex-builder -c optee_test -a arm64
flex-builder -i merge-component -a arm64 -m ls1012grapeboard
```

This will create a boot partition tarball (`build/images/bootpartition_arm64_<version>.tgz`) and rootfs (`build/rfs/rootfs_ubuntu_bionic_arm64`). Use the `flex-installer` script to apply them to an SD card.

## Installing Linux to the SD card

You will need a physical linux machine and an 8GB or larger SD card.

Run the following command, where `/dev/sdx` is your SD card. The card will be erased.

```
flex-installer -b build/images/bootpartition_arm64_<version>.tgz -r build/rfs/rootfs_ubuntu_bionic_arm64 -d /dev/sdx
```

Unmount and eject the SD card.

```
udisksctl unmount -b /dev/sdx1
udisksctl unmount -b /dev/sdx2
udisksctl unmount -b /dev/sdx3
udisksctl power-off -b /dev/sdx
```

Insert the SD card to your grapeboard and power on. You should see linux boot. Log in with the following credentials:
```
Username: root
Password: root
```

# Running OP-TEE tests

This will run the OP-TEE test suite and verify that Linux can talk to OP-TEE.

```
tee-supplicant &
xtest -l 0
...
+-----------------------------------------------------
16081 subtests of which 1 failed
74 test cases of which 1 failed
0 test case was skipped
TEE test application done!
```

# Booting Grapeboard into recovery mode

These instructions taken from section 5.3 of the [Grapeboard BSP User Guide](https://www.grapeboard.com/wp-content/uploads/2018/05/scalys_grapeboard_bsp_user_guide_180518.pdf).

1. Connect the Grapeboard to your host PC and open a serial terminal at 115200 8N1. If you're using Putty on Windows, you must go to **Connection -> Serial** and set **Flow control** to **None**.
![Putty Flow Control](putty-flow-control.png)
1. Press and hold switch `S2` on the Grapeboard.
1. Power-up (or reset with switch `S1`) the Grapeboard
1. Release switch `S2` once U-boot prints the message: `Please release the rescue mode button (S2) to enter the recovery mode`

You can now issue commands at the U-Boot prompt.

