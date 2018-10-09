#####################################
#
# Copyright 2017 NXP
#
######################################

SHELL=/bin/bash
include $(FBDIR)/configs/$(CONFIGLIST)
include $(FBDIR)/include/repo.mk


all: ramdiskrfs initrds

.PHONY: ramdiskrfs
ramdiskrfs:
	@if [ ! -f ramdiskrfs/ramdisk_rootfs_arm64.ext4.gz ]; then mkdir -p ramdiskrfs && cd ramdiskrfs && \
	 wget -c $(ramdiskrfs_url)/ramdisk_rootfs_arm64.ext4.gz && cd -; fi
	@if [ ! -f ramdiskrfs/ramdisk_rootfs_arm32.ext4.gz ]; then mkdir -p ramdiskrfs && cd ramdiskrfs && \
	 wget -c $(ramdiskrfs_url)/ramdisk_rootfs_arm32.ext4.gz && cd -; fi


.PHONY: initrds
initrds:
	@if [ ! -d initrds -a -n "$(initrds_repo_url)" ]; then git clone $(initrds_repo_url); fi;

repo_fetch:
	@make ramdiskrfs
	@$(call repo-update,fetch,initrds)

repo_update_branch:
	@$(call repo-update,branch,initrds)

repo_update_tag:
	@$(call repo-update,tag,initrds)

repo_update_latest:
	@$(call repo-update,update,initrds)

repo_update_commit:
	@$(call repo-update,commit,initrds)
	
