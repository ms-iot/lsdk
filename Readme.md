Getting started on LS1012 Grapeboard
============

This document will walk you through building all components from source and developing OP-TEE TA's for [Scalys Grapeboard](https://www.grapeboard.com/). We will build firmware, linux image, and test applications for Scalys grapeboard.

## Reference

 - [Scalys Grapeboard Home](https://www.grapeboard.com/)
 - [LSDK (Layerscape SDK)](https://www.nxp.com/products/processors-and-microcontrollers/arm-based-processors-and-mcus/qoriq-layerscape-arm-processors/layerscape-software-development-kit-v18.09:LAYERSCAPE-SDK)
 - [LSDK Documentation (PDF)](https://www.nxp.com/docs/en/supporting-information/LSDK_REV18.09.pdf)
 - [LSDK Git Repositories](https://lsdk.github.io/components.html)
 - [Grapeboard BSP User Guide (PDF)](https://www.grapeboard.com/wp-content/uploads/2018/10/Scalys_Grapeboard-bsp-user-guide_18102018.pdf)

# Setting up your Grapeboard

You will need

 - 5-15V power supply
 - micro USB cable
 - 8GB or greater micro SD card
 - A physical machine with USB port running [Ubuntu 18.04 LTS](http://releases.ubuntu.com/18.04/)

You will interact with the device over the serial terminal, and eventually the network. U-Boot, PPA, and OP-TEE are stored on on-board NOR flash, and linux will be stored on the SD card.

## Serial Terminal

1. Connect the micro USB cable to the micro USB connector (next to the power connector). Your PC should recognize it as a USB/Serial device. If it does not, you can try the driver [here](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers).
2. Determine the COM port number from device manager.
3. Open a putty terminal at 115200 8N1. You must go to **Connection -> Serial** and set **Flow control** to **None**.
![Putty Flow Control](docs/putty-flow-control.png)
4. Power on the board by plugging in the power supply.

You should see spew from the bootloader in your putty terminal.

```
U-Boot 2017.11-00009-g5418f2df0d5-dirty (Oct 16 2018 - 17:37:42 -0700)

SoC:  LS1012AE Rev1.0 (0x87040010)
Clock Configuration:
       CPU0(A53):800  MHz
       Bus:      250  MHz  DDR:      1000 MT/s
Reset Configuration Word (RCW):
       00000000: 08000008 00000000 00000000 00000000
       00000010: 33050000 c000400c 40000000 00001800
       00000020: 00000000 00000000 00000000 000047d0
       00000030: 00000000 10c02120 00000096 00000000
I2C:   ready
...
```

Congratulations, you're ready to run commands at the U-Boot prompt.

# Install prerequisites

```
sudo apt install build-essential gcc-aarch64-linux-gnu g++-aarch64-linux-gnu u-boot-tools device-tree-compiler

```

# Building Firmware

Change directories to the root of this repository, and run

```
git submodule init
git submodule update --init --recursive
make firmware
```

This will build the following items:

 * U-Boot
   * `build/u-boot-with-spl-pbl.bin`
 * HAB Signature Data
   * `build/hdr_spl.out`
 * OP-TEE OS and PPA
   * `build/ppa.itb`
 * Boot script
   * `build/grapeboard_boot.scr`

These files must be written to NOR flash.

## Updating Firmware on NOR Flash

Copy `u-boot-with-spl-pbl.bin`, `hdr_spl.out`, and `ppa.itb` from the `build` directory to the root of a FAT-formatted SD card.

Boot into [recovery U-Boot](#booting-grapeboard-into-recovery-mode), then run the following u-boot commands:

```
# Update U-Boot
mmc rescan
fatload mmc 0:1 $load_addr u-boot-with-spl-pbl.bin
sf probe 0:0
sf erase u-boot 200000
sf write $load_addr u-boot $filesize

# Update CSF Header
mmc rescan
fatload mmc 0:1 $load_addr hdr_spl.out
sf probe 0:0
sf erase u-boot_hdr 40000
sf write $load_addr u-boot_hdr $filesize

# Update PPA+OPTEE
mmc rescan
fatload mmc 0:1 $load_addr ppa.itb
sf probe 0:0
sf erase ppa 100000
sf write $load_addr ppa $filesize
```

Reset the board. When it reboots, you should see it execute your firmware. You should see output like the following, which indicates that U-Boot SPL, OP-TEE, and U-Boot Proper are running.

```
U-Boot SPL 2018.09-00480-gdc28a9fa63-dirty (Jan 17 2019 - 11:17:15 -0800)
PPA Firmware: Version LSDK-18.09
SEC Firmware: 'loadables' present in config
loadables: 'trustedOS@1'
I/TC:
I/TC: OP-TEE version: v0.4.0-443-g9cdcf55b-dev #6 Sat Jan 26 05:59:52 UTC 2019 aarch64
I/TC: Successfully captured Cyres certificate chain
I/TC: Successfully captured Cyres private key
I/TC: Initialized
Trying to boot from RAM


U-Boot 2018.09-00480-gdc28a9fa63-dirty (Jan 17 2019 - 11:17:15 -0800)
```

# Building Linux

In the root of this repository, run the following command to build the linux kernel and RootFS.

```
make os
```

Linux is the combination of NXP's layerscape fork ([https://source.codeaurora.org/external/qoriq/qoriq-components/linux](https://source.codeaurora.org/external/qoriq/qoriq-components/linux) `tags/LSDK-18.09-V4.14`) and grapeboard patches. Grapeboard patches were taken from `git://git.scalys.com/lsdk/linux` branch `grapeboard-proto`. The grapeboard patches have been rebased on top of `tags/LSDK-18.09-V4.14`, and the result is stored at [https://github.com/ms-iot/linux branch](https://github.com/ms-iot/linux) branch `ms-iot-grapeboard`.

## Installing Linux to the SD card

You will need a physical linux machine and an 8GB or larger SD card.

Run the following command, where `/dev/sdx` is your SD card. All data on the card will be lost.

```
make sdcard DEV=/dev/sdx
```

When the script finishes, it is safe to remove the SD card.

Insert the SD card to your grapeboard and power on. You should see linux boot. You can log in and interact with the device over the serial terminal. The login credentials are:

```
Username: root
Password: root
```

You can determine the device's IP address by running `ifconfig`. Then, you can SSH into the device with the following credentials:

```
Username: user
Password: user
```

# Running OP-TEE tests

This will run the OP-TEE test suite, which will verify that Linux can talk to OP-TEE.

```
tee-supplicant &
xtest -l 0
```

You should see most of the tests pass:

```
...
+-----------------------------------------------------
16081 subtests of which 1 failed
74 test cases of which 1 failed
0 test case was skipped
TEE test application done!
```

# Developing OP-TEE TA's

1. Build optee\_os and optee\_client.
	```
	make optee optee_client
	```
1. Set required environment variables.
	```
	export TA_DEV_KIT_DIR=$PWD/build/optee/export-ta_arm64/
	export TEEC_EXPORT=$PWD/build/optee_client/export
	export HOST_CROSS_COMPILE=aarch64-linux-gnu-
	```
1. Change directories outside this repository, and clone `optee_examples`.
	```
	cd ..
	git clone https://github.com/linaro-swg/optee_examples.git
	```
1. Build the hello\_world TA and host app.
	```
	cd optee_examples/hello_world
	make
	```
1. Copy host executable and TA to target.
	```
	scp host/optee_example_hello_world user@<ip>:~
	scp ta/*.ta user@<ip>:~
	```
1. On the target, copy the `.ta` file to `/lib/optee_armtz`.
	```
	cp *.ta /lib/optee_armtz
	```
1. On the target, in the root SSH session, start the TEE supplicant.
	```
	tee-supplicant &
	```
1. In another window on the target, run the host executable.
	```
	./optee_example_hello_world
	```

You should see the following printed from the host executable:
```
user@localhost:~# sudo ./optee_example_hello_world
Invoking TA to increment 42
TA incremented value to 43
```

And the following from the supplicant window:
```
root@localhost:~# tee-supplicant
D/TA:  TA_CreateEntryPoint:39 has been called
D/TA:  TA_OpenSessionEntryPoint:68 has been called
I/TA:  Hello World!
D/TA:  inc_value:105 has been called
I/TA:  Got value: 42 from NW
I/TA:  Increase value to: 43
I/TA:  Goodbye!
D/TA:  TA_DestroyEntryPoint:50 has been called
```

# Booting Grapeboard into recovery mode

These instructions taken from section 5.3 of the [Grapeboard BSP User Guide](https://www.grapeboard.com/wp-content/uploads/2018/05/scalys_grapeboard_bsp_user_guide_180518.pdf).

1. Connect the Grapeboard to your host PC and open a serial terminal at 115200 8N1. If you're using Putty on Windows, you must go to **Connection -> Serial** and set **Flow control** to **None**.
![Putty Flow Control](docs/putty-flow-control.png)
1. Press and hold switch `S2` on the Grapeboard.
1. Power-up (or reset with switch `S1`) the Grapeboard
1. Release switch `S2` once U-boot prints the message: `Please release the rescue mode button (S2) to enter the recovery mode`

You can now issue commands at the U-Boot prompt.

# Secure Boot
For documentation about enabling secure boot on the Grapeboard please see [grapeboard_secureboot.md](docs/grapeboard_secureboot.md)

# fTPM 
In order to use fTPM TPM driver, please start tee-supplicant and load the driver first:
```
tee-supplicant &
modprobe tpm_ftpm_optee
```
