#####################################
#
# Copyright 2017 NXP
#
######################################

SHELL=/bin/bash
include $(FBDIR)/configs/$(CONFIGLIST)
include $(FBDIR)/include/repo.mk

LINUX_REPO_LIST = $(KERNEL_TREE) cryptodev-linux

all: setup-repo build-linux

setup-repo:
	@$(call fetch-git-tree,$(KERNEL_TREE))

build-linux:
ifeq ($(CONFIG_BUILD_LINUX), y)
	@curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	$(call fbprint_n,"Building $(KERNEL_TREE) with $$curbrch") && \
	$(call fbprint_n,"KERNEL_CFG = $(KERNEL_CFG)") && \
	$(call fbprint_n,"Compiler = `$(CROSS_COMPILE)gcc --version | head -1`") && \
	if [ $(DESTARCH) = arm64 ]; then locarch=arm64; dtbstr=freescale/*.dtb; dtbdir=dts; \
	elif [ $(DESTARCH) = arm32 -a $(MACHINE) = ls1021atwr ]; then \
	locarch=arm; dtbstr=ls*.dtb; dtbdir=dts; extname=v7; elif [ $(DESTARCH) = arm32 ]; then locarch=arm; dtbstr=freescale/*.dtb; \
	dtbdir=dts; extname=v8; cp -rf $(KERNEL_PATH)/arch/arm64/boot/dts/freescale $(KERNEL_PATH)/arch/arm/boot/dts; \
	elif [ $(DESTARCH) = ppc32 -o $(DESTARCH) = ppc64 ]; then locarch=powerpc; dtbstr=fsl/*.dtb; dtbdir=; fi; \
	opdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	if [ $(DESTARCH) = arm32 -a $(MACHINE) = ls1021atwr ]; then opdir=$$opdir/v7; \
	elif [ $(DESTARCH) = arm32 -a $(MACHINE) != ls1021atwr ]; then opdir=$$opdir/v8; fi && \
	if [ ! -d $$opdir ]; then mkdir -p $$opdir; fi && \
	if [ ! -f $$opdir/.config ]; then $(MAKE) $(KERNEL_CFG) -C $(KERNEL_PATH) O=$$opdir 1>/dev/null; fi && \
	if [ "$(BUILDARG)" = "custom" ]; then $(MAKE) menuconfig -C $(KERNEL_PATH) O=$$opdir && \
	$(call fbprint_d,"Custom kernel config: $$opdir/.config") && exit; fi; \
	if [ "`echo $(BUILDARG) | cut -d: -f1`" = "fragment" ]; then mergeconfig=`echo $(BUILDARG) | cut -d: -f2`; \
	echo -e "\n$(KERNEL_TREE): Total Config List = $(KERNEL_CFG) $$mergeconfig\n" && \
	$(MAKE) $$mergeconfig -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ "$(ENDIANTYPE)" = "be" ]; then sed -i 's/# CONFIG_CPU_BIG_ENDIAN is not set/CONFIG_CPU_BIG_ENDIAN=y/' $$opdir/.config; \
	echo Big-Endian enabled!; fi && $(MAKE) -j$(JOBS) all -C $(KERNEL_PATH) O=$$opdir && \
	if [ $(DESTARCH) = arm32 ]; then $(MAKE) -j$(JOBS) uImage LOADADDR=80008000 -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = ppc32 -o $(DESTARCH) = ppc64 ]; then $(MAKE) -j$(JOBS) uImage -C $(KERNEL_PATH) O=$$opdir; fi && \
	$(MAKE) modules -C $(KERNEL_PATH) O=$$opdir && \
	$(MAKE) INSTALL_MOD_PATH=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH) modules_install -C $(KERNEL_PATH) O=$$opdir && \
	if [ $(DESTARCH) = arm32 -o $(DESTARCH) = arm64 ]; then $(MAKE) zinstall \
	INSTALL_PATH=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH) -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = arm32 -a $(MACHINE) = ls1021atwr ]; then $(MAKE) ls1021a-twr.dtb -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = arm32 -a $(MACHINE) != ls1021atwr ]; then $(MAKE) "$(ARM32_DTB_LIST)" -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = arm64 ]; then $(MAKE) "$(ARM64_DTB_LIST)" -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = ppc32 ]; then $(MAKE) "$(PPC32_DTB_LIST)" -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = ppc64 ]; then $(MAKE) "$(PPC64_DTB_LIST)" -C $(KERNEL_PATH) O=$$opdir; fi && \
	if [ $(DESTARCH) = ppc32 -o $(DESTARCH) = ppc64 ]; then cp $$opdir/arch/$$locarch/boot/uImage $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH); \
	tail -c +65 $$opdir/arch/$$locarch/boot/uImage > $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/Image.gz; fi && \
	if [ $(DESTARCH) = arm64 ]; then cp $$opdir/arch/$$locarch/boot/Image* \
	$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH); fi && \
	if [ $(DESTARCH) = arm32 ]; then cp $$opdir/arch/$$locarch/boot/uImage \
	$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/uImage.$$extname; \
	cp $$opdir/arch/$$locarch/boot/zImage $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/zImage.$$extname; fi && \
	ls $$opdir/arch/$$locarch/boot/$$dtbdir/$$dtbstr | grep -iE 'rdb|frdm|frwy|twr|qds|ds|grapeboard' | xargs -I {} cp {} \
	$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH) && \
	if [ $(DESTARCH) = arm32 ]; then rm -f $(FBDIR)/build/linux/$(KERNEL_TREE)/arm32/fsl-ls2*.dtb; fi && \
	ls -l $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH) && \
	$(call fbprint_d,"$(KERNEL_TREE) $$curbrch in $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)")
endif


.PHONY: cryptodev-linux
cryptodev-linux:
ifeq ($(CONFIG_BUILD_CRYPTODEV_LINUX), y)
	@$(call fetch-git-tree,cryptodev-linux)
	@$(call fetch-git-tree,$(KERNEL_TREE))
	@if [ ! -d $(FBDIR)/build/linux/kernel/$(DESTARCH) ]; then cd $(FBDIR) && \
	 flex-builder -c linux -a $(DESTARCH) -f $(CONFIGLIST) && cd -; fi && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	 if [ $(DESTARCH) = arm32 -a $(MACHINE) = ls1021atwr ]; then opdir=$$opdir/v7; \
	 elif [ $(DESTARCH) = arm32 -a $(MACHINE) != ls1021atwr ]; then opdir=$$opdir/v8; fi && \
	 cd cryptodev-linux && $(call fbprint_b,"CRYPTODEV_LINUX") && export KERNEL_DIR=$$opdir && \
	 export KERNEL_MAKE_OPTS="-lcrypto -L$(RFSDIR)/usr/lib/aarch64-linux-gnu" && $(MAKE) && $(MAKE) install && \
	 ls -l $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/lib/modules/*/extra/cryptodev.ko && \
	 $(call fbprint_d,"CRYPTODEV_LINUX")
endif


perf:
	@$(call fetch-git-tree,$(KERNEL_TREE))
	@curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	 if [ $(DESTARCH) = arm32 -a $(MACHINE) = ls1021atwr ]; then opdir=$$opdir/v7; \
	 elif [ $(DESTARCH) = arm32 -a $(MACHINE) != ls1021atwr ]; then opdir=$$opdir/v8; fi && \
	 $(call fbprint_b,"kernel tools/perf") && \
	 if [ ! -d $$opdir ]; then mkdir -p $$opdir; fi && \
	 if [ ! -f $$opdir/.config ]; then $(MAKE) $(KERNEL_CFG) -C $(KERNEL_PATH) O=$$opdir 1>/dev/null; fi && \
	 $(MAKE) -j$(JOBS) tools/perf -C $(KERNEL_PATH) O=$$opdir && \
	 cp $$opdir/tools/perf/perf $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH) && \
	 ls -l $(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/perf && \
	 $(call fbprint_d,"kernel tools/perf")

.PHONY: lttng-modules
lttng-modules:
ifeq ($(CONFIG_BUILD_LTTNG), y)
	@$(call fetch-git-tree,lttng-modules)
	@$(call fetch-git-tree,$(KERNEL_TREE))
	@curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	 if [ $(DESTARCH) = arm32 -a $(MACHINE) = ls1021atwr ]; then opdir=$$opdir/v7; \
	 elif [ $(DESTARCH) = arm32 -a $(MACHINE) != ls1021atwr ]; then opdir=$$opdir/v8; fi && \
	 if [ ! -d $$opdir ]; then mkdir -p $$opdir; fi && \
	 if ! grep CONFIG_STACKTRACE=y $$opdir/.config 1>/dev/null 2>&1; then cd $(FBDIR) && \
	 flex-builder -c linux -B fragment:lttng.config -a $(DESTARCH) -f $(CONFIGLIST) && cd -; fi && \
	 cd lttng-modules && $(call fbprint_b,"LTTng modules") && \
	 $(MAKE) KERNELDIR=$(KERNEL_PATH) O=$$opdir && \
	 $(MAKE) KERNELDIR=$(KERNEL_PATH) O=$$opdir modules_install && \
	 $(call fbprint_d,"LTTng modules")
endif


repo_fetch:
	@echo -e "\nfetch linux repositories ..."
	@$(call repo-update,fetch,$(LINUX_REPO_LIST))

repo_update_branch:
	@echo -e "\nlinux repositories update for branch ..."
	@$(call repo-update,branch,$(LINUX_REPO_LIST))

repo_update_tag:
	@echo -e "\nlinux repositories update for tag ..."
	@$(call repo-update,tag,$(LINUX_REPO_LIST))

repo_update_latest:
	@echo -e "\nlinux repositories update to latest HEAD commit ..."
	@$(call repo-update,update,$(LINUX_REPO_LIST))

repo_update_commit:
	@echo -e "\nlinux repositories update to specified commit ID ..."
	@$(call repo-update,commit,$(LINUX_REPO_LIST))
