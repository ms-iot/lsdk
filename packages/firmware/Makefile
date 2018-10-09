#####################################
#
# Copyright 2017 NXP
#
#####################################

SHELL=/bin/bash
include $(FBDIR)/configs/$(CONFIGLIST)
include $(FBDIR)/include/repo.mk


PPASUBDIRS = soc-ls1012 soc-ls1043 soc-ls1046 soc-ls1088 soc-ls2080 soc-ls2088


firmware: uboot uefi ppa rcw mc-utils bin-firmware

uboot:
ifeq ($(CONFIG_BUILD_UBOOT), y)
	@$(call fetch-git-tree,$(UBOOT_TREE))
ifeq ($(MACHINE), all)
	@for brd in $(MACHINE_LIST); do \
		if [ $(DESTARCH) = arm64 -a $$brd = ls1021atwr ]; then continue; \
		elif [ $(DESTARCH) = arm32 ] && [ $$brd != ls1021atwr -a $$brd != ls1043ardb -a $$brd != ls1046ardb ]; then continue; fi; \
		$(call fbprint_n,"*** machine = $$brd ***"); \
		if [ $$brd = ls2088ardb ]; then brdmsk=*ls208?ardb*; elif [ $$brd = ls1088ardb ]; then brdmsk=ls1088ardb_[^pb]*; else brdmsk=*$$brd*; fi && \
		for cfg in `ls $(UBOOT_TREE)/configs/$$brdmsk 2>/dev/null | cut -d/ -f3 | \
		        grep -iE 'qspi|sdcard|emmc|nor|nand|rdb_defconfig|rdb-pc_defconfig|rdb_SECURE_BOOT|ds_defconfig'`; do \
		    $(call build-uboot-target,$$cfg) \
		done; \
	 done

else
	@$(call fbprint_b,"uboot for $(MACHINE)")
	@if [ $(MACHINE) = ls2088ardb ]; then \
	     brdmsk=*ls208?ardb*; \
	 elif [ $(MACHINE) = ls1088ardb ]; then \
	     brdmsk=ls1088ardb_[^pb]*; \
	 elif echo $(MACHINE) | grep ^[p,t,P,T].* 1>/dev/null; then \
	     brdmsk=*`tr '[a-z]' '[A-Z]' <<< $(MACHINE)`*; \
	 else \
	     brdmsk=*$(MACHINE)*; \
	 fi && \
	 if [ -z "$(BOOTTYPE)" ]; then \
	     for cfg in `ls $(UBOOT_TREE)/configs/$$brdmsk 2>/dev/null | cut -d/ -f3 | \
	             grep -iE 'qspi|sdcard|emmc|nor|nand|rdb_defconfig|rdb-pc_defconfig|rdb_SECURE_BOOT|ds_defconfig'`; do \
		$(call build-uboot-target,$$cfg) \
	     done; \
	 else \
	     if [ $(BOOTTYPE) = nor ]; then \
	         for cfg in `ls $(UBOOT_TREE)/configs/$$brdmsk 2>/dev/null | cut -d/ -f3 | \
		         grep -iE 'nor|rdb_defconfig|rdb-pc_defconfig|rdb_SECURE_BOOT|ds_defconfig'`; do \
		    $(call build-uboot-target,$$cfg) \
		 done; \
	     else \
	         for cfg in `ls $(UBOOT_TREE)/configs/$$brdmsk 2>/dev/null | cut -d/ -f3 | grep -iE "$(BOOTTYPE)"`; do \
		     $(call build-uboot-target,$$cfg) \
		 done; \
	     fi; \
	 fi
endif

define build-uboot-target
	if echo $1 | grep -E 'ls1021atwr';  then export ARCH=arm; export CROSS_COMPILE=arm-linux-gnueabihf-; dtbstr=-dtb; \
	elif echo $1 | grep ^[p,t,P,T].* 1>/dev/null;  then export ARCH=powerpc; export CROSS_COMPILE=powerpc-linux-; \
	     if [ ! -f $(FBDIR)/build/rfs/rootfs_buildroot_ppc32_tiny/host/bin/powerpc-linux-gcc ]; then \
	         flex-builder -i mktoolchain -a ppc32 -f $(CONFIGLIST); fi; \
	     if ! echo $(PATH) | grep ppc32; then export PATH="$(FBDIR)/build/rfs/rootfs_buildroot_ppc32_tiny/host/bin:$(PATH)";fi; \
	else export ARCH=arm64;export CROSS_COMPILE=aarch64-linux-gnu-; dtbstr=-dtb; fi && \
	if [ $(MACHINE) != all ]; then brd=$(MACHINE); fi && \
	opdir=$(FBDIR)/build/firmware/u-boot/$$brd/output/$1 && \
	if [ ! -d $$opdir ]; then mkdir -p $$opdir; fi &&  \
	$(call fbprint_b,"config = $1") && if [ ! -f $$opdir/.config ]; then $(MAKE) -C $(UBOOT_TREE) $1 O=$$opdir; fi && \
	$(MAKE) -C $(UBOOT_TREE) -j$(JOBS) O=$$opdir && \
	if echo $1 | grep -iE 'sdcard|nand'; then \
	   if [ -f $$opdir/u-boot-with-spl-pbl.bin ]; then \
	       srcbin=u-boot-with-spl-pbl.bin; \
	   else \
	       srcbin=u-boot-with-spl.bin; \
	   fi; \
	   if echo $1 | grep -iE 'SECURE_BOOT'; then \
	       if echo $1 | grep -iE 'sdcard'; then \
	           cp $$opdir/spl/u-boot-spl.bin $(FBDIR)/build/firmware/u-boot/$$brd/uboot_$${brd}_sdcard_spl.bin ; \
	           cp $$opdir/u-boot-dtb.bin $(FBDIR)/build/firmware/u-boot/$$brd/uboot_$${brd}_sdcard_dtb.bin ; \
	       elif echo $1 | grep -iE 'nand'; then \
		   cp $$opdir/spl/u-boot-spl.bin $(FBDIR)/build/firmware/u-boot/$$brd/uboot_$${brd}_nand_spl.bin ; \
		   cp $$opdir/u-boot-dtb.bin $(FBDIR)/build/firmware/u-boot/$$brd/uboot_$${brd}_nand_dtb.bin ; \
	       fi; \
	   fi; \
	else \
	    srcbin=u-boot$$dtbstr.bin; \
	fi && \
	tgtbin=uboot_`echo $1|sed -r 's/(.*)(_.*)/\1/'`.bin && \
	cp $$opdir/$$srcbin $(FBDIR)/build/firmware/u-boot/$$brd/$$tgtbin && \
	$(call fbprint_d,"$(FBDIR)/build/firmware/u-boot/$$brd/$$tgtbin");
endef
endif


.PHONY: uefi
uefi:
ifeq ($(CONFIG_BUILD_UEFI), y)
	@$(call fbprint_b,"UEFI")
	@$(call fetch-git-tree,qoriq-uefi-binary)
	@for brd in "$(uefi_machine_list)"; do \
	       if [ ! -d $(FBDIR)/build/firmware/uefi/$$brd ]; then mkdir -p $(FBDIR)/build/firmware/uefi/$$brd ; fi; \
	        if [ ! -f $(FBDIR)/build/firmware/uefi/$$brd/*RDB_EFI* ]; then \
	            cp qoriq-uefi-binary/$$brd/*.fd $(FBDIR)/build/firmware/uefi/$$brd/; \
	        fi; \
	 done
	@if [ ! -d $(FBDIR)/build/firmware/uefi/grub ]; then mkdir -p $(FBDIR)/build/firmware/uefi/grub; fi
	@cp qoriq-uefi-binary/grub/BOOTAA64.EFI $(FBDIR)/build/firmware/uefi/grub
endif


.PHONY: rcw
rcw:
ifeq ($(CONFIG_BUILD_RCW), y)
	@$(call fbprint_b,"RCW")
	@$(call fetch-git-tree,$(rcw_repo))
	@if [ ! -d $(FBDIR)/build/firmware/rcw ]; then mkdir -p $(FBDIR)/build/firmware/rcw; fi
	@for brd in $(MACHINE_LIST) ls2088ardb_rev1.1; do \
             if [ "ls1088ardb_pb" = $$brd ];then \
                 continue; \
             fi && \
             $(MAKE) -C $(rcw_repo)/$$brd; \
	     $(MAKE) -C $(rcw_repo)/$$brd install DESTDIR=$(FBDIR)/build/firmware/rcw/$$brd; done && \
	 rm -f $(FBDIR)/build/firmware/rcw/*/README &&  $(call fbprint_d,"RCW")
endif


.PHONY: ppa
ppa:
ifeq ($(CONFIG_BUILD_PPA), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"PPA source")
	@$(call fetch-git-tree,ppa-generic)
	@find ppa-generic/ppa -name soc-l* | cut -d/ -f3 | xargs -i mkdir -p $(FBDIR)/build/firmware/ppa/{}
	@cd ppa-generic/ppa && \
	 if [ $(MACHINE) = all ]; then \
	     for name in $(PPASUBDIRS); do ./build rdb-fit `echo $$name | cut -d- -f2`; \
		cp -f $$name/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/$$name; done; \
	     if [ -f $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa.itb ] ; then mv $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa.itb \
	        $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa_rdb.itb; fi; \
	     ./build frwy-fit ls1012 && cp -f soc-ls1012/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa_frwy.itb; \
         elif [ $(MACHINE) = ls1012afrwy ]; then \
             ./build frwy-fit ls1012 && cp -f soc-ls1012/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa_frwy.itb; \
	 else \
	     socname=`echo $(MACHINE)|tr -cd [:digit:]` && \
	     ./build rdb-fit ls$$socname && cp soc-ls$$socname/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/soc-ls$$socname && \
	     if [ -f $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa.itb ]; then mv $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa.itb \
	        $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa_rdb.itb; \
	     fi && ls -l $(FBDIR)/build/firmware/ppa/soc-ls$$socname/*.itb; \
	 fi && $(call fbprint_d,"PPA source")
endif
endif

ppa-optee:
ifeq ($(CONFIG_BUILD_PPA), y)
ifeq ($(DESTARCH),arm64)
ifeq ($(CONFIG_BUILD_OPTEE), y)
	@$(call fetch-git-tree,ppa-generic)
	@find ppa-generic/ppa -name soc-l* | cut -d/ -f3 | xargs -i mkdir -p $(FBDIR)/build/firmware/ppa/{}
ifeq ($(MACHINE), all)
	@for brd in "$(optee_machine_list)"; do $(call build-ppa-optee,$$brd) done
else
	@$(call build-ppa-optee,$(MACHINE))
endif

define build-ppa-optee
	for optee_brd in "$(optee_machine_list)"; do \
		board=`echo $${optee_brd}|tr -cd [:digit:]`; \
		mcno=`echo $1|tr -cd [:digit:]`; \
		if [ "$$optee_brd" =  "$1" ]; then\
			echo "Building PPA source with OPTEE-OS for $$optee_brd"; \
			if [ ! -f $(FBDIR)/packages/apps/optee_os/out/arm-plat-ls/core/tee_$1.bin ]; then \
				$(call fbprint_n,"Build OPTEE-OS first before starting PPA ..."); \
				cd $(FBDIR) && flex-builder -c optee_os -a $(DESTARCH) -m $1 -f $(CONFIGLIST);\
			fi && \
			if [ ! -f $(FBDIR)/packages/apps/optee_os/out/arm-plat-ls/core/tee_$1.bin ]; then \
				$(call fbprint_e,"building OPTEE-OS. Doing Nothing & Exiting ..."); \
			else \
			       echo "Copying tee_$1.bin to ppa/soc-ls$$mcno before starting building PPA ..." ; \
			       cp $(FBDIR)/packages/apps/optee_os/out/arm-plat-ls/core/tee_$1.bin \
				  $(FBDIR)/packages/firmware/ppa-generic/ppa/soc-ls$$mcno/tee.bin ;\
			       cd $(FBDIR)/packages/firmware/ppa-generic/ppa && \
			       if [ "$$optee_brd" = ls1012ardb ]; then ./build rdb-fit spd=on ls$$mcno && \
			           cp -f soc-ls1012/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa_rdb.itb; \
			       elif [ "$$optee_brd" = ls1012afrwy ]; then ./build frwy-fit spd=on ls$$mcno && \
			           cp -f soc-ls1012/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/soc-ls1012/ppa_frwy.itb; \
			       else ./build rdb-fit spd=on ls$$mcno && cp soc-ls$$mcno/build/obj/ppa.itb \
			           $(FBDIR)/build/firmware/ppa/soc-ls$$mcno; \
			       fi; \
			       ls -l $(FBDIR)/build/firmware/ppa/soc-ls$$mcno/*.itb && $(call fbprint_d,"ppa-optee soc-ls$$mcno"); \
		       fi; \
		fi; \
	done
endef
endif
endif
endif


ppa-fuse:
ifeq ($(CONFIG_BUILD_PPA), y)
ifeq ($(DESTARCH),arm64)
ifeq ($(CONFIG_BUILD_CST), y)
	@$(call fetch-git-tree,ppa-generic)
	@find ppa-generic/ppa -name soc-l* | cut -d/ -f3 | xargs -i mkdir -p $(FBDIR)/build/firmware/ppa/{}
	@if [ "$(MACHINE)" = all ]; then $(call fbprint_e,"please specify -m option"); exit 1; fi
	@$(call build-ppa-fuse,$(MACHINE))

define build-ppa-fuse
	echo "Building PPA source with fuse_scr.bin for $1"; \
	mcno=`echo $1|tr -cd [:digit:]`; \
	if [ ! -d $(FBDIR)/packages/apps/cst/ ]; then \
		$(call fbprint_n,"Build CST before starting PPA ..."); \
		cd $(FBDIR) && flex-builder -c cst -f $(CONFIGLIST);\
	fi && \
	if [ ! -d $(FBDIR)/packages/apps/cst/ ]; then \
		$(call fbprint_e,"building CST. Doing Nothing & Exiting ..."); \
	else \
		echo "Generate & copy fuse_scr.bin to ppa/soc-ls$$mcno before starting building PPA ..." ; \
		if [ $1 = ls1088ardb -o $1 = ls1088ardb_pb -o $1 = ls2088ardb ]; then \
		    fusescrinput=input_files/gen_fusescr/ls2088_1088/input_fuse_file; \
		else \
		    fusescrinput=input_files/gen_fusescr/ls104x_1012/input_fuse_file; \
		fi; \
		cd $(FBDIR)/packages/apps/cst/ && ./gen_fusescr $$fusescrinput; \
		cp fuse_scr.bin $(FBDIR)/packages/firmware/ppa-generic/ppa/soc-ls$$mcno/; \
		cd $(FBDIR)/packages/firmware/ppa-generic/ppa && ./build rdb-fit fuse=on ls$$mcno;\
		cp soc-ls$$mcno/build/obj/ppa.itb $(FBDIR)/build/firmware/ppa/soc-ls$$mcno/ppa.itb;\
		ls -l $(FBDIR)/build/firmware/ppa/soc-ls$$mcno/*.itb && $(call fbprint_d,"ppa-fuse soc-ls$$mcno"); \
	fi;
endef
endif
endif
endif


ifeq ($(CONFIG_BUILD_PPA_BIN), y)
	@$(call fbprint_b,"PPA binary")
	@$(call fetch-git-tree,qoriq-ppa-binary)
	@if [ ! -h $(FBDIR)/build/firmware/ppa ]; then \
	 ln -s $(FBDIR)/packages/firmware/qoriq-ppa-binary $(FBDIR)/build/firmware/ppa; fi
	@$(call fbprint_d,"PPA binary")
endif


.PHONY: mc-utils
mc-utils:
	@$(call fbprint_b,"mc-utils")
	@$(call fetch-git-tree,mc-utils)
	@if [ ! -h $(FBDIR)/build/firmware/mc-utils ]; then \
         ln -s $(FBDIR)/packages/firmware/mc-utils $(FBDIR)/build/firmware/mc-utils; fi
	@$(MAKE) -C mc-utils/config && ls -l $(FBDIR)/build/firmware/mc-utils/config/*/RDB/*.dtb && $(call fbprint_d,"mc-utils")


bin-firmware: qoriq-fm-ucode qoriq-qe-ucode qoriq-mc-binary qoriq-firmware-cortina qoriq-engine-pfe-bin

.PHONY: qoriq-fm-ucode
qoriq-fm-ucode:
	@$(call fetch-git-tree,qoriq-fm-ucode)
	@if [ ! -h $(FBDIR)/build/firmware/qoriq-fm-ucode ]; then \
	 ln -s $(FBDIR)/packages/firmware/qoriq-fm-ucode $(FBDIR)/build/firmware/qoriq-fm-ucode; fi
	@ls -l $(FBDIR)/build/firmware/qoriq-fm-ucode/*.bin && $(call fbprint_d,"qoriq-fm-ucode")


.PHONY: qoriq-qe-ucode
qoriq-qe-ucode:
	@$(call fetch-git-tree,qoriq-qe-ucode)
	@if [ ! -h $(FBDIR)/build/firmware/qoriq-qe-ucode ]; then \
	 ln -s $(FBDIR)/packages/firmware/qoriq-qe-ucode $(FBDIR)/build/firmware/qoriq-qe-ucode; fi
	@ls -l $(FBDIR)/build/firmware/qoriq-qe-ucode/*.bin && $(call fbprint_d,"qoriq-qe-ucode")


.PHONY: qoriq-mc-binary
qoriq-mc-binary:
	@$(call fetch-git-tree,qoriq-mc-binary)
	@if [ ! -h $(FBDIR)/build/firmware/qoriq-mc-binary ]; then \
	 ln -s $(FBDIR)/packages/firmware/qoriq-mc-binary $(FBDIR)/build/firmware/qoriq-mc-binary; fi
	@ls -l $(FBDIR)/build/firmware/qoriq-mc-binary/*/*.itb && $(call fbprint_d,"qoriq-mc-binary")


.PHONY: qoriq-firmware-cortina
qoriq-firmware-cortina:
	@$(call fetch-git-tree,qoriq-firmware-cortina)
	@if [ ! -h $(FBDIR)/build/firmware/qoriq-firmware-cortina ]; then \
	 ln -s $(FBDIR)/packages/firmware/qoriq-firmware-cortina $(FBDIR)/build/firmware/qoriq-firmware-cortina; fi
	@$(call fbprint_d,"qoriq-firmware-cortina")


.PHONY: qoriq-engine-pfe-bin
qoriq-engine-pfe-bin:
	@$(call fetch-git-tree,qoriq-engine-pfe-bin)
	@if [ ! -h $(FBDIR)/build/firmware/qoriq-engine-pfe-bin ]; then \
	 ln -s $(FBDIR)/packages/firmware/qoriq-engine-pfe-bin $(FBDIR)/build/firmware/qoriq-engine-pfe-bin; fi
	@ls -l $(FBDIR)/build/firmware/qoriq-engine-pfe-bin/ls1012a/*/ && $(call fbprint_d,"qoriq-engine-pfe-bin")


repo_fetch:
	@echo -e "\nfetch firmware repositories ..."
	@$(call repo-update,fetch,$(FIRMWARE_REPO_LIST))

repo_update_branch:
	@echo -e "\nfirmware repositories update for branch ..."
	@$(call repo-update,branch,$(FIRMWARE_REPO_LIST))

repo_update_tag:
	@echo -e "\nfirmware repositories update for tag ..."
	@$(call repo-update,tag,$(FIRMWARE_REPO_LIST))

repo_update_latest:
	@echo -e "\nfirmware repositories update to latest HEAD commit ..."
	@$(call repo-update,update,$(FIRMWARE_REPO_LIST))

repo_update_commit:
	@echo -e "\nfirmware repositories update to specified commit ID ..."
	@$(call repo-update,commit,$(FIRMWARE_REPO_LIST))
