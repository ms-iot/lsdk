# Copyright 2018 NXP
#
# SPDX-License-Identifier:     BSD-3-Clause
#
# U-Boot script to flash image to 'current' or 'other' bank of NOR/QSPI flash device for Layerscape platforms
#
# Supported platforms:
# LS1021ATWR, LS1012ARDB, LS1012AFRWY, LS1043ARDB, LS1046ARDB, LS1088ARDB, LS2088ARDB
#
# mkimage -T script -C none -d flash_images.sh flash_images.scr
# or
# flex-builder -i mkflashscr
#
# flash_images.scr is stored in offset 0x9C0000 of NOR/QSPI flash and in the boot partition of SD/USB/SATA disk
#
# Usage:
#     load $bd_type $bd_part $load_addr flash_images.scr
#     source $load_addr
#     Example:
#     load mmc 0:2 a0000000 flash_images.scr
#     source a0000000
#
# Refer to docs/lsdk_build_install.txt for details
#

if test -z "$board"; then
    echo You must setenv board to board name, e.g. setenv board ls1043ardb
    exit
fi
if test -z "$bd_type"; then
    echo You must setenv bd_type to mmc, usb, or scsi
    exit
fi

# Start USB if necessary
test $bd_type = "usb" && usb start

if test -z "$bd_part"; then
    echo bd_part is not set, using default 0:2 for the partition number!
    bd_part=0:2
fi

if test -z "$bank"; then
    if test $board = ls1021atwr -o $board = ls1043ardb -o $board = ls2088ardb; then
	echo You must setenv bank to current or other
	echo WARNING: to avoid damaging the working image in current bank, prefer to setenv bank to other!
	exit
    fi
fi

if test -z "$img_load_addr"; then
    img_load_addr=0xa1000000
fi

# user can set img variable to just flash single image
if test -z "$img"; then
    echo You must setenv img variable!
    echo To flash single image: setenv img to rcw, uboot, ppa, mcfw, mcdpc, mcdpl, fman, qe, pfe, phy, dtb, linux_itb
    echo To flash all images: setenv img to all
    if load $bd_type $bd_part $img_load_addr flash_images.scr; then
	echo You can load various image from the following directory in flash_images/$board:
	ls $bd_type $bd_part flash_images/$board
    fi
    echo If necessary, you can override the default setting for variable: bd_part, flash_type, rcw_img, uboot_img, ppa_img
    echo dtb_img, linux_itb_img, qe_img, fman_img, phy_img, mcfw_img, mcdpl_img, mcdpc_img
    exit
fi

# set default protect off command to "true"
pt_off_cmd=true

# Set default image file names which can be overrided in uboot prompt by users
image_path=/flash_images/$board

if test $board = ls1021atwr; then
    if test -z "$rcw_img"; then
	rcw_img=$image_path/rcw/SSR_PNS_30/rcw_1200.bin
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls1021atwr_nor.bin
    fi
    if test -z "$qe_img"; then
	qe_img=/flash_images/fsl_qe_ucode_1021_10_A.bin
    fi
    if test -z "$dtb_img"; then
	dtb_img=/ls1021a-twr.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=nor
    fi
    pt_off_cmd="protect off"
    efs="+$filesize"
    erase_cmd=erase
    write_cmd=cp.b
elif test $board = ls1012ardb; then
    if test -z "$rcw_img"; then
	rcw_img=$image_path/rcw/R_SPNH_3508/rcw_1000_default.bin.swapped
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls1012ardb_qspi.bin
    fi
    if test -z "$ppa_img"; then
	ppa_img=$image_path/ppa_rdb.itb
    fi
    if test -z "$pfe_img"; then
	pfe_img=/flash_images/pfe_fw_sbl.itb
    fi
    if test -z "$dtb_img"; then
	dtb_img=/fsl-ls1012a-rdb.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=qspi
    fi
    # currently qspi doesn't support sf protect lock/unlock feature, so just echo it.
    pt_off_cmd="echo sf protect unlock"
    efs="$filesize"
    erase_cmd="sf erase"
    write_cmd="sf write"
elif test $board = ls1012afrwy; then
    if test -z "$rcw_img"; then
	rcw_img=$image_path/rcw/N_SSNP_3305/rcw_1000_default.bin.swapped
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls1012afrwy_qspi.bin
    fi
    if test -z "$ppa_img"; then
	ppa_img=$image_path/ppa_frwy.itb
    fi
    if test -z "$pfe_img"; then
	pfe_img=/flash_images/pfe_fw_sbl.itb
    fi
    if test -z "$dtb_img"; then
	dtb_img=/fsl-ls1012a-frwy.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=qspi
    fi
    pt_off_cmd="echo sf protect unlock"
    efs="$filesize"
    erase_cmd="sf erase"
    write_cmd="sf write"
elif test $board = ls1043ardb; then
    if test -z "$rcw_img"; then
	rcw_img=$image_path/rcw/RR_FQPP_1455/rcw_1600.bin
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls1043ardb.bin
    fi
    if test -z "$ppa_img"; then
	ppa_img=$image_path/ppa.itb
    fi
    if test -z "$fman_img"; then
	fman_img=/flash_images/fsl_fman_ucode_ls1043_r1.1_106_4_18.bin
    fi
    if test -z "$qe_img"; then
	qe_img=/flash_images/iram_Type_A_LS1021a_r1.0.bin
    fi
    if test -z "$phy_img"; then
	phy_img=/flash_images/cs4315-cs4340-PHY-ucode.txt
    fi
    if test -z "$dtb_img"; then
	dtb_img=/fsl-ls1043a-rdb-sdk.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=nor
    fi
    pt_off_cmd="protect off"
    efs="+$filesize"
    erase_cmd=erase
    write_cmd=cp.b
elif test $board = ls1046ardb; then
    if test -z "$rcw_img"; then
	rcw_img=$image_path/rcw/RR_FFSSPPPH_1133_5559/rcw_1800_qspiboot.bin.swapped
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls1046ardb_qspi.bin
    fi
    if test -z "$ppa_img"; then
	ppa_img=$image_path/ppa.itb
    fi
    if test -z "$fman_img"; then
	fman_img=/flash_images/fsl_fman_ucode_ls1046_r1.0_106_4_18.bin
    fi
    if test -z "$qe_img"; then
	qe_img=/flash_images/iram_Type_A_LS1021a_r1.0.bin
    fi
    if test -z "$phy_img"; then
	phy_img=/flash_images/cs4315-cs4340-PHY-ucode.txt
    fi
    if test -z "$dtb_img"; then
	dtb_img=/fsl-ls1046a-rdb-sdk.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=qspi
    fi
    pt_off_cmd="echo sf protect unlock"
    efs="$filesize"
    erase_cmd="sf erase"
    write_cmd="sf write"
elif test $board = ls1088ardb; then
    if test -z "$rcw_img"; then
	rcw_img=$image_path/rcw/FCQQQQQQQQ_PPP_H_0x1d_0x0d/rcw_1600_qspi.bin
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls1088ardb_qspi.bin
    fi
    if test -z "$ppa_img"; then
	ppa_img=$image_path/ppa.itb
    fi
    if test -z "$mcfw_img"; then
	mcfw_img=$image_path/mc_10.8.0_ls1088a_20180515.itb
    fi
    if test -z "$mcdpc_img"; then
	mcdpc_img=$image_path/dpc-bman-4M.0x1D-0x0D.dtb
    fi
    if test -z "$mcdpl_img"; then
	mcdpl_img=$image_path/dpl-eth.0x1D_0x0D.dtb
    fi
    if test -z "$dtb_img"; then
	dtb_img=/fsl-ls1088a-rdb.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=qspi
    fi
    pt_off_cmd="echo sf protect unlock"
    efs="$filesize"
    erase_cmd="sf erase"
    write_cmd="sf write"
elif test $board = ls1088ardb_pb; then
    if test -z "$rcw_img"; then
        rcw_img=$image_path/rcw/FCSSRR_PPPP_0x1d_0x13/rcw_1600_qspi.bin
    fi
    if test -z "$uboot_img"; then
        uboot_img=$image_path/uboot_ls1088ardb_pb_qspi.bin
    fi
    if test -z "$ppa_img"; then
        ppa_img=$image_path/ppa.itb
    fi
    if test -z "$mcfw_img"; then
        mcfw_img=$image_path/mc_10.8.0_ls1088a_20180515.itb
    fi
    if test -z "$mcdpc_img"; then
        mcdpc_img=$image_path/dpc-bman-4M.0x1D-0x0D.dtb
    fi
    if test -z "$mcdpl_img"; then
        mcdpl_img=$image_path/dpl-eth.0x1D_0x0D.dtb
    fi
    if test -z "$dtb_img"; then
        dtb_img=/fsl-ls1088a-rdb.dtb
    fi
    if test -z "$flash_type"; then
        flash_type=qspi
    fi
    pt_off_cmd="echo sf protect unlock"
    efs="$filesize"
    erase_cmd="sf erase"
    write_cmd="sf write"
elif test $board = ls2088ardb; then
    if test -z "$rcw_img"; then
	if itest.b *0x1e000a4 == 0x10; then    # Rev 1.0 Si based on SVR value
	    rcw_img=$image_path/rcw/rev1.0/FFFFFFFF_PP_HH_0x2a_0x41/rcw_1800.bin
	elif itest.b *0x1e000a4 == 0x11; then  # Rev 1.1 Si based on SVR value
	    rcw_img=$image_path/rcw/rev1.1/FFFFFFFF_PP_HH_0x2a_0x41/rcw_2000.bin
	else
	    echo ERROR: Unknown SoC revision; exit
	fi
    fi
    if test -z "$uboot_img"; then
	uboot_img=$image_path/uboot_ls2080ardb.bin
    fi
    if test -z "$ppa_img"; then
	ppa_img=$image_path/ppa.itb
    fi
    if test -z "$mcfw_img"; then
	mcfw_img=$image_path/mc_10.8.0_ls2088a_20180515.itb
    fi
    if test -z "$mcdpc_img"; then
	mcdpc_img=$image_path/dpc-bman-4M.0x2A_0x41.dtb
    fi
    if test -z "$mcdpl_img"; then
	mcdpl_img=$image_path/dpl-eth.0x2A_0x41.dtb
    fi
    if test -z "$phy_img"; then
	phy_img=/flash_images/cs4315-cs4340-PHY-ucode.txt
    fi
    if test -z "$dtb_img"; then
	dtb_img=/fsl-ls2088a-rdb.dtb
    fi
    if test -z "$flash_type"; then
	flash_type=nor
    fi
    pt_off_cmd="protect off"
    efs="+$filesize"
    erase_cmd=erase
    write_cmd=cp.b
fi

if test -z "$linux_itb_img"; then
    if test $board = ls1021atwr; then
	linux_itb_img=/lsdk_linux_arm32_tiny.itb
    else
	linux_itb_img=/lsdk_linux_arm64_tiny.itb
    fi
fi

if test $board = ls1021atwr -o $board = ls1043ardb; then
    # IFC-NOR flash on LS1021ATWR and LS1043ARDB
    if test $bank = other; then
	addr_rcw=0x64000000
	addr_uboot=0x64100000
	addr_ppa=0x64400000
	addr_fman=0x64900000
	addr_qe=0x64940000
	addr_eth=0x64980000
	addr_dtb=0x64f00000
	addr_kernel=0x65000000
    elif test $bank = current; then
	addr_rcw=0x60000000
	addr_uboot=0x60100000
	addr_ppa=0x60400000
	addr_fman=0x60900000
	addr_qe=0x60940000
	addr_eth=0x60980000
	addr_dtb=0x60f00000
	addr_kernel=0x61000000
    else
	echo Error: invalid $bank for bank!
	exit
    fi
elif test $board = ls1012ardb -o $board = ls1046ardb -o $board = ls1088ardb  -o $board = ls1088ardb_pb; then
    # QSPI flash on LS1012ARDB, LS1046ARDB and LS1088ARDB
    addr_rcw=0x0
    addr_uboot=0x00100000
    addr_ppa=0x00400000
    addr_fman=0x00900000
    addr_qe=0x00940000
    addr_eth=0x00980000
    addr_mcfw=0x00a00000
    addr_mcdpl=0x00d00000
    addr_mcdpc=0x00e00000
    addr_dtb=0x00f00000
    addr_kernel=0x01000000
elif test $board = ls1012afrwy; then
    # base firmware in 2MB QSPI-NOR flash on LS1012AFRWY
    addr_rcw=0x0
    addr_eth=0x00020000
    addr_ppa=0x00060000
    addr_uboot=0x00100000
    # kernel+dtb+ramdisk itb in 128MB NAND flash
    addr_kernel=0x0
elif test $board = ls2088ardb; then
    if test $bank = other; then
	addr_rcw=0x584000000
	addr_uboot=0x584100000
	addr_ppa=0x584400000
	addr_eth=0x584980000
	addr_mcfw=0x584a00000
	addr_mcdpl=0x584d00000
	addr_mcdpc=0x584e00000
	addr_dtb=0x584f00000
	addr_kernel=0x585000000
    elif test $bank = current; then
	addr_rcw=0x580000000
	addr_uboot=0x580100000
	addr_ppa=0x580400000
	addr_eth=0x580980000
	addr_mcfw=0x580a00000
	addr_mcdpl=0x580d00000
	addr_mcdpc=0x580e00000
	addr_dtb=0x580f00000
	addr_kernel=0x581000000
    else
	echo Error: invalid $bank for bank!
	exit
    fi
fi

if test $board = ls1046ardb -o $board = ls1088ardb -o $board = ls1088ardb_pb; then    # probe QSPI flash
    if test $bank = other; then
	echo Selecting other bank
	sf probe 0:1
    elif test $bank = current; then
	sf probe 0:0
    else
	echo Error: invalid $bank for bank.  Aborting
	exit
    fi
elif test $board = ls1012ardb; then
    if test $bank = bank2; then
	echo Selecting bank2
	i2c mw 0x24 0x7 0xfc; i2c mw 0x24 0x3 0xf5
    elif test $bank = bank1; then
	echo Selecting bank1
	i2c mw 0x24 0x7 0xfc; i2c mw 0x24 0x3 0xf4
    elif test $bank != current; then
	echo Error: bank choices are bank1, bank2, or current for bank.  Aborting
	exit
    fi
    sf probe
elif test $board = ls1012afrwy; then
    if test $bank != current; then
	echo Only current bank is supported on ls1012afrwy.  Aborting
	exit
    fi
    sf probe
fi

echo Starting to flash $bank bank of $flash_type flash according to LSDK standard flash layout:
echo Using bd_type   = $bd_type
echo Using bd_part   = $bd_part
echo Using img       = $img

if test "$img" = rcw; then
    # RCW+PBI image
    echo Using addr_rcw $addr_rcw for rcw_img $rcw_img
    if load $bd_type $bd_part $img_load_addr $rcw_img && $pt_off_cmd $addr_rcw $efs && $erase_cmd $addr_rcw +$filesize && $write_cmd $img_load_addr $addr_rcw $filesize; then
	echo Success: flashed $rcw_img
    else
	echo Failed to flash $rcw_img
    fi
    exit
elif test "$img" = uboot; then
    # U-Boot image
    echo Using addr_uboot $addr_uboot for uboot_img $uboot_img
    if load $bd_type $bd_part $img_load_addr $uboot_img && $pt_off_cmd $addr_uboot $efs && $erase_cmd $addr_uboot +$filesize && $write_cmd $img_load_addr $addr_uboot $filesize; then
	echo Success: flashed $uboot_img
    else
	echo Failed to flash $uboot_img
    fi
    exit
elif test "$img" = ppa; then
    # PPA image
    echo Using addr_ppa $addr_ppa for ppa_img $ppa_img
    if load $bd_type $bd_part $img_load_addr $ppa_img && $pt_off_cmd $addr_ppa $efs && $erase_cmd $addr_ppa +$filesize && $write_cmd $img_load_addr $addr_ppa $filesize; then
	echo Success: flashed $ppa_img
    else
	echo Failed to flash $ppa_img
    fi
    exit
elif test "$img" = mcfw; then
    # DPAA2 MC firmware
    echo Using addr_mcfw $addr_mcfw for mcfw_img $mcfw_img
    if load $bd_type $bd_part $img_load_addr $mcfw_img && $pt_off_cmd $addr_mcfw $efs && $erase_cmd $addr_mcfw +$filesize && $write_cmd $img_load_addr $addr_mcfw $filesize; then
	echo Success: flashed $mcfw_img to $addr_mcfw
    else
	echo Failed to flash $mcfw_img
    fi
    exit
elif test "$img" = mcdpl; then
    # DPAA2 MC DPL
    echo Using addr_mcdpl $addr_mcdpl for mcdpl_img $mcdpl_img
    if load $bd_type $bd_part $img_load_addr $mcdpl_img && $pt_off_cmd $addr_mcdpl $efs && $erase_cmd $addr_mcdpl +$filesize && $write_cmd $img_load_addr $addr_mcdpl $filesize; then
	echo Success: flashed $mcdpl_img to $addr_mcdpl
    else
	echo Failed to flash $mcdpl_img
    fi
    exit
elif test "$img" = mcdpc; then
    # DPAA2 MC DPC
    echo Using addr_mcdpc $addr_mcdpc for mcdpc_img $mcdpc_img
    if load $bd_type $bd_part $img_load_addr $mcdpc_img && $pt_off_cmd $addr_mcdpc $efs && $erase_cmd $addr_mcdpc +$filesize && $write_cmd $img_load_addr $addr_mcdpc $filesize; then
	echo Success: flashed $mcdpc_img to $addr_mcdpc
    else
	echo Failed to flash $mcdpc_img
    fi
    exit
elif test "$img" = fman; then
    # DPAA1 FMan ucode firmware
    echo Using addr_fman $addr_fman for fman_img $fman_img
    if load $bd_type $bd_part $img_load_addr $fman_img && $pt_off_cmd $addr_fman $efs && $erase_cmd $addr_fman +$filesize && $write_cmd $img_load_addr $addr_fman $filesize; then
	echo Success: flashed $fman_img
    else
	echo Failed to flash $fman_img
    fi
    exit
elif test "$img" = pfe; then
    # PFE firmware on LS1012A
    echo Using addr_eth $addr_eth for pfe_img $pfe_img
    if load $bd_type $bd_part $img_load_addr $pfe_img && $pt_off_cmd $addr_eth $efs && $erase_cmd $addr_eth +$filesize && $write_cmd $img_load_addr $addr_eth $filesize; then
	echo Success: flashed $pfe_img
    else
	echo Failed to flash $pfe_img
    fi
    exit
elif test "$img" = phy; then
    # Cortina PHY firmware
    echo Using addr_eth $addr_eth for phy_img $phy_img
    if load $bd_type $bd_part $img_load_addr $phy_img && $pt_off_cmd $addr_eth $efs && $erase_cmd $addr_eth +$filesize && $write_cmd $img_load_addr $addr_eth $filesize; then
	echo Success: flashed $phy_img
    else
	echo Failed to flash $phy_img
    fi
    exit
elif test "$img" = qe; then
    # QE ucode firmware
    echo Using addr_qe $addr_qe for qe_img $qe_img
    if load $bd_type $bd_part $img_load_addr $qe_img && $pt_off_cmd $addr_qe $efs && $erase_cmd $addr_qe +$filesize && $write_cmd $img_load_addr $addr_qe $filesize; then
	echo Success: flashed $qe_img
    else
	echo Failed to flash $qe_img
    fi
    exit
elif test "$img" = dtb; then
    # DTB image
    echo Using addr_dtb $addr_dtb for dtb_img $dtb_img
    echo "222 $pt_off_cmd $addr_dtb $efs $erase_cmd $addr_dtb +$filesize"
    if load $bd_type $bd_part $img_load_addr $dtb_img && $pt_off_cmd $addr_dtb $efs && $erase_cmd $addr_dtb +$filesize && $write_cmd $img_load_addr $addr_dtb $filesize; then
	echo Success: flashed $dtb_img
    else
	echo Failed to flash $dtb_img
    fi
    exit
elif test "$img" = linux_itb; then
    # linux itb image
    echo Using addr_kernel $addr_kernel for linux_itb_img $linux_itb_img
    if load $bd_type $bd_part $img_load_addr $linux_itb_img && $pt_off_cmd $addr_kernel $efs && $erase_cmd $addr_kernel +$filesize && $write_cmd $img_load_addr $addr_kernel $filesize; then
	echo Success: flashed $linux_itb_img
    else
	echo Failed to flash $linux_itb_img
    fi
    exit
elif test "$img" != all; then
    echo ERROR: invalid $img for img!
    exit
fi


# flash all images to the specified bank in case of img=all

# RCW+PBI
if load $bd_type $bd_part $img_load_addr $rcw_img && $pt_off_cmd $addr_rcw $efs && $erase_cmd $addr_rcw +$filesize && $write_cmd $img_load_addr $addr_rcw $filesize; then
    echo Success: flashed $rcw_img to $addr_rcw
else
    echo Failed to flash $rcw_img
fi

# U-Boot
if load $bd_type $bd_part $img_load_addr $uboot_img && $pt_off_cmd $addr_uboot $efs && $erase_cmd $addr_uboot +$filesize && $write_cmd $img_load_addr $addr_uboot $filesize; then
    echo Success: flashed $uboot_img to $addr_uboot
else
    echo Failed to flash $uboot_img
fi

# PPA
if load $bd_type $bd_part $img_load_addr $ppa_img && $pt_off_cmd $addr_ppa $efs && $erase_cmd $addr_ppa +$filesize && $write_cmd $img_load_addr $addr_ppa $filesize; then
    echo Success: flashed $ppa_img to $addr_ppa
else
    echo Failed to flash $ppa_img
fi

# DPAA1 FMan ucode
if test $board = ls1043ardb -o $board = ls1046ardb; then
    if load $bd_type $bd_part $img_load_addr $fman_img && $pt_off_cmd $addr_fman $efs && $erase_cmd $addr_fman +$filesize && $write_cmd $img_load_addr $addr_fman $filesize; then
	echo Success: flashed $fman_img to $addr_fman
    else
	echo Failed to flash $fman_img
    fi
fi

# QE ucode
if test $board = ls1021atwr -o $board = ls1043ardb -o $board = ls1046ardb; then
    if load $bd_type $bd_part $img_load_addr $qe_img && $pt_off_cmd $addr_qe $efs && $erase_cmd $addr_qe +$filesize && $write_cmd $img_load_addr $addr_qe $filesize; then
	echo Success: flashed $qe_img to $addr_qe
    else
	echo Failed to flash $qe_img
    fi
fi

# Ethernet PHY firmware
if test $board = ls1043ardb -o $board = ls1046ardb -o $board = ls1088ardb -o $board = ls1088ardb_pb -o $board = ls2088ardb; then
    if load $bd_type $bd_part $img_load_addr $phy_img && $pt_off_cmd $addr_eth $efs && $erase_cmd $addr_eth +$filesize && $write_cmd $img_load_addr $addr_eth $filesize; then
	echo Success: flashed $phy_img to $addr_eth
    else
	echo Failed to flash $phy_img
    fi
elif test $board = ls1012ardb -o $board = ls1012afrwy; then
# PFE firmware
    if load $bd_type $bd_part $img_load_addr $pfe_img && $pt_off_cmd $addr_eth $efs && $erase_cmd $addr_eth +$filesize && $write_cmd $img_load_addr $addr_eth $filesize; then
	echo Success: flashed $pfe_img to $addr_eth
    else
	echo Failed to flash $pfe_img
    fi
fi

# DPAA2 MC firmware
if test $board = ls1088ardb  -o $board = ls1088ardb_pb -o $board = ls2088ardb; then
    if load $bd_type $bd_part $img_load_addr $mcfw_img && $pt_off_cmd $addr_mcfw $efs && $erase_cmd $addr_mcfw +$filesize && $write_cmd $img_load_addr $addr_mcfw $filesize; then
	echo Success: flashed $mcfw_img to $addr_mcfw
    else
	echo Failed to flash $mcfw_img
    fi
fi

# DPAA2 DPL firmware
if test $board = ls2088ardb; then
    if load $bd_type $bd_part $img_load_addr $mcdpl_img && $pt_off_cmd $addr_mcdpl $efs && $erase_cmd $addr_mcdpl +$filesize && $write_cmd $img_load_addr $addr_mcdpl $filesize; then
	echo Success: flashed $mcdpl_img to $addr_mcdpl
    else
	echo Failed to flash $mcdpl_img
    fi
fi

# DPAA2 DPC firmware
if test $board = ls2088ardb; then
    if load $bd_type $bd_part $img_load_addr $mcdpc_img && $pt_off_cmd $addr_mcdpc $efs && $erase_cmd $addr_mcdpc +$filesize && $write_cmd $img_load_addr $addr_mcdpc $filesize; then
	echo Success: flashed $mcdpc_img to $addr_mcdpc
    else
	echo Failed to flash $mcdpc_img
    fi
fi


# DTB
if load $bd_type $bd_part $img_load_addr $dtb_img && $pt_off_cmd $addr_dtb $efs && $erase_cmd $addr_dtb +$filesize && $write_cmd $img_load_addr $addr_dtb $filesize; then
    echo Success: flashed $dtb_img to $addr_dtb
else
    echo Failed to flash $dtb_img
fi

# Kernel itb
if load $bd_type $bd_part $img_load_addr $linux_itb_img && $pt_off_cmd $addr_kernel $efs && $erase_cmd $addr_kernel +$filesize && $write_cmd $img_load_addr $addr_kernel $filesize; then
    echo Success: flashed $linux_itb_img to $addr_kernel
else
    echo Failed to flash $linux_itb_img
fi 

echo Completed!

if test $board = ls1043ardb -o $board = ls1046ardb; then
    echo run "cpld reset altbank" to boot U-Boot from other bank.
elif test $board = ls1088ardb -o $board = ls1088ardb_pb -o $board = ls2088ardb; then
    echo run "qixis_reset altbank" to boot U-Boot from other bank.
fi
