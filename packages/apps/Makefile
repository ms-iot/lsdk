#####################################
#
# Copyright 2017 NXP
#
######################################

SHELL=/bin/bash
include $(FBDIR)/configs/$(CONFIGLIST)
include $(FBDIR)/include/repo.mk


.PHONY: all

all: $(APPS_REPO_LIST)
	@$(call fbprint_d,"apps components")

.PHONY: restool
restool:
ifeq ($(CONFIG_BUILD_RESTOOL), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"restool")
	@$(call fetch-git-tree,restool)
	@$(MAKE) -C restool
	@$(MAKE) -C restool install && \
	 $(call fbprint_d,"restool")
endif
endif


.PHONY: odp
odp:
ifeq ($(CONFIG_BUILD_ODP), y)
ifeq ($(DESTARCH),arm64)
	@$(call fetch-git-tree,odp)
	@curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 kerneloutdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	 if echo $$curbrch|grep 4.14; then echo ODP is not supported in kernel 4.14;exit 0;fi && \
	 if [ ! -d $(FBDIR)/build/linux/kernel/$(DESTARCH)/lib/modules ] || \
	 [ ! -f $$kerneloutdir/include/config/kernel.release ]; then $(call build_dependent_linux); fi &&
	 $(call fbprint_b,"ODP") && cd odp && ./bootstrap && \
	 ./configure --with-platform=linux-dpaa2 --host=aarch64-linux-gnu --with-cunit-path="$(RFSDIR)/usr" \
	 --enable-test-vald && $(MAKE) -j$(JOBS) && export PRE_INSTALL=$(DESTDIR) && $(MAKE) install && \
	 cd kern && $(call fbprint_b,"ODP-KNI") && export KERNEL_CFG_PATH=$$kerneloutdir && $(MAKE) -j$(JOBS) \
	 KERNEL_PATH=$$kerneloutdir && if [ -n "$(MODULES_PATH)" ]; then cp -f odpfsl_kni.ko $(MODULES_PATH)/extra; fi && \
	 $(call fbprint_d,"ODP")
endif
endif


.PHONY: ofp
ofp:
ifeq ($(CONFIG_BUILD_OFP), y)
ifeq ($(DESTARCH),arm64)
	@$(call fetch-git-tree,ofp)
	@if [ ! -d $(DESTDIR)/usr/local/odp ]; then exit 0; fi && $(call fbprint_b,"OFP") && \
	 cd ofp && ./bootstrap  && export CFLAGS="-I$(DESTDIR)/usr/local/include" && \
	 export LDFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu/ -L$(DESTDIR)/lib" && \
	 ./configure CC=$(CROSS_COMPILE)gcc --host=aarch64-linux-gnu --disable-shared \
	 --with-odp=$(DESTDIR)/usr/local && $(MAKE) -j$(JOBS) && $(MAKE) install && \
	 $(call fbprint_d,"OFP")
endif
endif


.PHONY: dpdk
dpdk:
ifeq ($(CONFIG_BUILD_DPDK), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"DPDK")
	@$(call fetch-git-tree,dpdk)
	@if [ ! -f $(RFSDIR)/usr/include/aarch64-linux-gnu/openssl/opensslconf.h ]; then $(call build_dependent_rfs); fi && \
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 kerneloutdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	 if [ ! -f $$kerneloutdir/include/generated/utsrelease.h ]; then echo $(call build_dependent_linux); fi && \
	 cd $(FBDIR)/packages/apps/dpdk && export CROSS=$(CROSS_COMPILE) && export RTE_KERNELDIR=$$kerneloutdir \
	 && export RTE_SDK=$(PWD) && export RTE_TARGET=arm64-dpaa-linuxapp-gcc \
	 && export OPENSSL_PATH=$(RFSDIR)/usr && $(MAKE) install T=arm64-dpaa-linuxapp-gcc \
	 DESTDIR=${DESTDIR}/usr/local CONFIG_RTE_EAL_IGB_UIO=n CONFIG_RTE_KNI_KMOD=y CONFIG_RTE_LIBRTE_PMD_OPENSSL=y \
	 EXTRA_CFLAGS="-I$(RFSDIR)/usr/include/aarch64-linux-gnu -fPIC" EXTRA_LDFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu" && cd - \
	 && echo -e "\nBuilding DPDK Examples ..." && cd $(FBDIR)/packages/apps/dpdk/examples \
	 && export CROSS=$(CROSS_COMPILE) && export RTE_SDK=$(FBDIR)/packages/apps/dpdk \
	 && export RTE_TARGET=arm64-dpaa-linuxapp-gcc && export OPENSSL_PATH=$(RFSDIR)/usr && export RTE_SDK_BIN=$(DESTDIR)/usr/local \
	 && $(MAKE) -j$(JOBS) -C l2fwd && $(MAKE) -j$(JOBS) -C l3fwd && $(MAKE) -j$(JOBS) -C cmdif \
	 && $(MAKE) -j$(JOBS) -C l2fwd-qdma && $(MAKE) -j$(JOBS) -C l2fwd-crypto \
	 CONFIG_RTE_LIBRTE_PMD_OPENSSL=y EXTRA_CFLAGS="-I$(RFSDIR)/usr/include/aarch64-linux-gnu" EXTRA_LDFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu" \
	 && $(MAKE) -j$(JOBS) -C vhost && $(MAKE) -j$(JOBS) -C ipsec-secgw CONFIG_RTE_LIBRTE_PMD_OPENSSL=y EXTRA_CFLAGS="-I$(DESTDIR)/usr/local/include" \
	 EXTRA_LDFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu"  && $(MAKE) -j$(JOBS) -C ip_fragmentation && $(MAKE) -j$(JOBS) -C ip_reassembly  \
	 && $(MAKE) -j$(JOBS) -C kni && find . -perm -111 -a -type f | xargs -I {} cp {} $(DESTDIR)/usr/local/bin \
	 && mkdir -p $(DESTDIR)/usr/local/dpdk/cmdif/include && mkdir -p $(DESTDIR)/usr/local/dpdk/cmdif/lib \
	 && cp cmdif/lib/client/fsl_cmdif_client.h cmdif/lib/server/fsl_cmdif_server.h cmdif/lib/shbp/fsl_shbp.h $(DESTDIR)/usr/local/dpdk/cmdif/include/ \
	 && cp cmdif/lib/arm64-dpaa-linuxapp-gcc/librte_cmdif.a ${DESTDIR}/usr/local/dpdk/cmdif/lib/ \
	 && mkdir -p $(DESTDIR)/usr/local/dpdk/examples/ipsec_secgw \
	 && cp -f ipsec-secgw/*.cfg ${DESTDIR}/usr/local/dpdk/examples/ipsec_secgw && cd - \
	 && echo -e "\nInstalling dpdk-extras ...$(DESTDIR) " && cp -rf $(FBDIR)/packages/apps/dpdk/nxp/* $(DESTDIR)/usr/local/dpdk/ \
	 && rm -rf $(DESTDIR)/usr/local/share/dpdk/examples \
	 && cd $(DESTDIR)/usr/local/bin && rm -f dpdk-pdump && rm -f dpdk-pmdinfo && rm -f dpdk-procinfo && rm -f dpdk-test-crypto-perf && cd - && \
	 $(call fbprint_d,"DPDK")
endif
endif

.PHONY: vpp
vpp:
ifeq ($(CONFIG_BUILD_VPP), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"VPP")
	@$(call fetch-git-tree,vpp)
	@if [ ! -f $(RFSDIR)/usr/include/aarch64-linux-gnu/openssl/opensslconf.h ]; then \
             $(call build_dependent_rfs); \
         fi && \
	 if [ ! -d $(DESTDIR)/usr/local/dpdk ]; then \
             echo building dependent DPDK ... && \
	     cd $(FBDIR) && flex-builder -c dpdk -f $(CONFIGLIST) && cd -; \
         fi && \
         export CROSS_PREFIX=aarch64-linux-gnu && \
         export ARCH=arm64 && \
         export EXTRA_INC=$(RFSDIR)/usr/include/aarch64-linux-gnu && \
         export EXTRA_LIBS=$(RFSDIR)/lib/aarch64-linux-gnu && \
         export OPENSSL_PATH=$(RFSDIR)/usr && \
         export DPDK_PATH=$(DESTDIR)/usr/local && \
	 cd $(FBDIR)/packages/apps/vpp && \
	 $(MAKE) install-dep && \
         cd - && \
         cd $(FBDIR)/packages/apps/vpp/build-root && \
         make distclean && ./bootstrap.sh && \
         $(MAKE) V=0 PLATFORM=dpaa TAG=dpaa install-deb && \
         mkdir -p ${DESTDIR}/usr/local/vpp && \
         cp -v *.deb ${DESTDIR}/usr/local/vpp/ && \
         cd - && \
	 $(call fbprint_d,"VPP")
endif
endif

.PHONY: pktgen-dpdk
pktgen-dpdk:
ifeq ($(CONFIG_BUILD_PKTGEN_DPDK), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"pktgen-dpdk")
	@$(call fetch-git-tree,pktgen-dpdk)
	@cd pktgen-dpdk && export CROSS=$(CROSS_COMPILE) && export RTE_SDK=$(FBDIR)/packages/apps/dpdk && \
	 export RTE_TARGET=arm64-dpaa-linuxapp-gcc && $(MAKE) EXTRA_CFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu" && \
	 cp -f Pktgen.lua ${DESTDIR}/usr/bin && cp -f app/arm64-dpaa-linuxapp-gcc/pktgen ${DESTDIR}/usr/bin && \
	 $(call fbprint_d,"pktgen-dpdk")
endif
endif


.PHONY: ovs-dpdk
ovs-dpdk:
ifeq ($(CONFIG_BUILD_OVS_DPDK), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"OVS_DPDK")
	@$(call fetch-git-tree,ovs-dpdk)
	@if [ ! -d $(RFSDIR)/usr/lib/aarch64-linux-gnu ]; then $(call build_dependent_rfs); fi && \
	 if [ ! -d $(DESTDIR)/usr/local/dpdk ]; then echo building dependent DPDK ... && \
	 cd $(FBDIR) && flex-builder -c dpdk -f $(CONFIGLIST) && cd -; fi && \
	 cd ovs-dpdk && export CROSS=$(CROSS_COMPILE) && export RTE_SDK=$(FBDIR)/packages/apps/dpdk && \
	 export RTE_TARGET=arm64-dpaa-linuxapp-gcc && ./boot.sh && export LDFLAGS="-L$(RFSDIR)/lib/aarch64-linux-gnu" && \
	 export LIBS="-ldl -lnuma -lssl" && ./configure --prefix=/usr/local --host=aarch64-linux-gnu \
	 --with-dpdk=$(DESTDIR)/usr/local --with-openssl=$(RFSDIR)/usr CFLAGS="-g -Wno-cast-align -Ofast \
	 -I$(DESTDIR)/usr/local/include/dpdk -I$(RFSDIR)/usr/include -I$(RFSDIR)/usr/include/aarch64-linux-gnu -lpthread -lssl" && \
	 $(MAKE) -j$(JOBS) install && cd - && $(call fbprint_d,"OVS_DPDK")
endif
endif


.PHONY: flib
flib:
ifeq ($(CONFIG_BUILD_FLIB), y)
	@$(call fbprint_b,"FLIB")
	@$(call fetch-git-tree,flib)
	@$(MAKE) -C flib install && $(call fbprint_d,"FLIB")
endif


.PHONY: fmlib
fmlib:
ifeq ($(CONFIG_BUILD_FMLIB), y)
	@$(call fbprint_b,"FMLIB")
	@$(call fetch-git-tree,fmlib)
	@if [ ! -d $(KERNEL_PATH)/include/uapi/linux/fmd ]; then $(call build_dependent_linux); fi && \
	 cd fmlib && export KERNEL_SRC=$(KERNEL_PATH) && \
	 $(MAKE) clean && $(MAKE) && $(MAKE) install-libfm-arm && $(call fbprint_d,"FMLIB")
endif


.PHONY: fmc
fmc:
ifeq ($(CONFIG_BUILD_FMC), y)
	@$(call fbprint_b,"FMC")
	@$(call fetch-git-tree,fmc)
	@if [ $(DESTARCH) = arm64 -a $(DISTROTYPE) = ubuntu ]; then host=aarch64-linux-gnu; \
	 elif [ $(DESTARCH) = arm32 -a $(DISTROTYPE) = ubuntu ]; then host=arm-linux-gnueabihf; \
	 elif [ $(DESTARCH) = arm64 -a $(DISTROTYPE) = buildroot ]; then host=aarch64-buildroot-linux-gnu; \
	 elif [ $(DESTARCH) = arm32 -a $(DISTROTYPE) = buildroot ]; then host=arm-buildroot-linux-gnueabi; fi && \
	 if [ $(DISTROTYPE) = ubuntu ]; then sysrootdir=$(RFSDIR); elif [ $(DISTROTYPE) = buildroot ]; \
	 then sysrootdir=$(RFSDIR)/../host/$$host/sysroot; fi && \
	 if [ ! -d $(FBDIR)/packages/apps/fmlib/include/fmd/Peripherals ]; then cd $(FBDIR) && \
	 flex-builder -c fmlib -a $(DESTARCH) -f $(CONFIGLIST) && cd -; fi && \
	 if [ ! -f $(RFSDIR)/usr/include/libxml2/libxml/parser.h ]; then cd $(FBDIR) && \
	 flex-builder -i mkrfs -r $(DISTROTYPE):$(DISTROSCALE) -a $(DESTARCH) -f $(CONFIGLIST) && cd -; fi && \
	 if [ ! -d $(KERNEL_PATH)/include/uapi/linux/fmd ]; then $(call build_dependent_linux); fi && \
	 if [ ! -f $(DESTDIR)/lib/libfm-arm.a ]; then echo building dependent fmlib && cd $(FBDIR) \
	 && flex-builder -c fmlib -f $(CONFIGLIST) && cd -; fi && \
	 export LDFLAGS="-L$$sysrootdir/lib -L$$sysrootdir/lib/$$host -L$$sysrootdir/usr/lib \
	 -Wl,-rpath=$$sysrootdir/lib/$$host:$$sysrootdir/usr/lib/$$host" && \
	 export CFLAGS="-I$$sysrootdir/usr/include/$$host -I$(FBDIR)/packages/apps/fmlib/include/fmd \
	 -I$(FBDIR)/packages/apps/fmlib/include/fmd/Peripherals \
	 -I$(FBDIR)/packages/apps/fmlib/include/fmd/integrations" && \
	 $(MAKE) clean -C fmc/source && \
	 $(MAKE) FMD_USPACE_HEADER_PATH=$(KERNEL_PATH)/include/uapi/linux/fmd \
	 FMLIB_HEADER_PATH=$(FBDIR)/packages/apps/fmlib/include \
	 LIBXML2_HEADER_PATH=$$sysrootdir/usr/include/libxml2 \
	 FMD_USPACE_LIB_PATH=$(DESTDIR)/lib  TCLAP_HEADER_PATH=$$sysrootdir/usr/include \
	 CXX=$(CROSS_COMPILE)g++ CC=$(CROSS_COMPILE)gcc -C fmc/source
	@install -d $(DESTDIR)/usr/local/bin; \
	 install -m 755 fmc/source/fmc $(DESTDIR)/usr/local/bin/fmc; \
	 install -d $(DESTDIR)/etc/fmc/config; \
	 install -m 644 fmc/etc/fmc/config/hxs_pdl_v3.xml $(DESTDIR)/etc/fmc/config; \
	 install -d $(DESTDIR)/usr/local/include/fmc; \
	 install fmc/source/fmc.h $(DESTDIR)/usr/local/include/fmc; \
	 install -d $(DESTDIR)/usr/local/lib/$$host; \
	 install fmc/source/libfmc.a $(DESTDIR)/usr/local/lib/$$host && \
	 $(call fbprint_d,"FMC")
endif


.PHONY: cst
cst:
ifeq ($(CONFIG_BUILD_CST), y)
	@$(call fbprint_b,"CST")
	@$(call fetch-git-tree,cst)
	@cd cst && $(MAKE) -j$(JOBS)
	@if [ -n "$(SECURE_PRI_KEY)" ]; then echo Using specified $(SECURE_PRI_KEY) and $(SECURE_PUB_KEY) ... ; \
	 cp -f $(SECURE_PRI_KEY) cst/srk.pri && cp -f $(SECURE_PUB_KEY) cst/srk.pub; \
	 elif [ ! -f cst/srk.pri -o ! -f cst/srk.pub ]; then cd cst && ./gen_keys 1024 && \
	 echo "Generated new keys !"; else echo "Using default keys srk.pri and srk.pub"; fi && \
	 $(call fbprint_d,"CST")
endif


.PHONY: aiopsl
aiopsl:
ifeq ($(CONFIG_BUILD_AIOPSL), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"AIOPSL")
	@$(call fetch-git-tree,aiopsl)
	@cd aiopsl && \
	 if [ ! -d $(DESTDIR)/usr/local/aiop/bin ]; then mkdir -p $(DESTDIR)/usr/local/aiop/bin; fi && \
	 cp -rf misc/setup/scripts $(DESTDIR)/usr/local/aiop  && \
	 cp -rf misc/setup/traffic_files $(DESTDIR)/usr/local/aiop && \
	 cp -rf demos/images/* $(DESTDIR)/usr/local/aiop/bin && \
	 $(call fbprint_d,"AIOPSL")
endif
endif


.PHONY: ceetm
ceetm:
ifeq ($(CONFIG_BUILD_CEETM), y)
	@$(call fbprint_b,"CEETM")
	@$(call fetch-git-tree,ceetm)
	@if [ ! -f $(FBDIR)/packages/apps/iproute2-4.15.0/tc/tc_util.h ]; then \
	 wget $(iproute2_src_url) && tar xzf iproute2-4.15.0.tar.gz; fi && \
	 export IPROUTE2_DIR=$(FBDIR)/packages/apps/iproute2-4.15.0 && \
	 cd $(FBDIR)/packages/apps/ceetm && $(MAKE) clean && $(MAKE) && $(MAKE) install && \
	 $(call fbprint_d,"CEETM")
endif


.PHONY: dce
dce:
ifeq ($(CONFIG_BUILD_DCE), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"DCE")
	@$(call fetch-git-tree,dce)
	@cd dce && if [ ! -f lib/qbman_userspace/Makefile ]; then git submodule update; fi && \
	 $(MAKE) && $(MAKE) install && $(call fbprint_d,"DCE")
endif
endif


optee: optee_os optee_client optee_test

.PHONY: optee_os
optee_os:
ifeq ($(CONFIG_BUILD_OPTEE), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"OPTEE_OS")
	@$(call fetch-git-tree,optee_os)
	@if [ $(MACHINE) = "all" ]; then\
		for brd in "$(optee_machine_list)"; do \
		    flex-builder -c optee_os -m $$brd -a $(DESTARCH) -f $(CONFIGLIST); \
		done;\
	else\
             if [ "ls1088ardb_pb" = $(MACHINE) ]; then brd=ls1088ardb; else brd=$(MACHINE); fi && \
	     cd $(FBDIR)/packages/apps/optee_os && $(MAKE) CFG_ARM64_core=y PLATFORM=ls-$$brd ARCH=arm;\
		$(CROSS_COMPILE)\objcopy -v -O binary out/arm-plat-ls/core/tee.elf out/arm-plat-ls/core/tee_$(MACHINE).bin;\
	     if [ $(MACHINE) = ls1012afrwy ]; then \
		mv out/arm-plat-ls/core/tee_$(MACHINE).bin out/arm-plat-ls/core/tee_$(MACHINE)_512mb.bin && \
		$(MAKE) -j$(JOBS) CFG_ARM64_core=y PLATFORM=ls-ls1012afrwy ARCH=arm CFG_DRAM0_SIZE=0x40000000 && \
		$(CROSS_COMPILE)\objcopy -v -O binary out/arm-plat-ls/core/tee.elf out/arm-plat-ls/core/tee_$(MACHINE).bin; \
             fi; \
	fi && rm -f out/arm-plat-ls/core/tee.bin && $(call fbprint_d,"OPTEE_OS")
endif
endif


.PHONY: optee_client
optee_client:
ifeq ($(CONFIG_BUILD_OPTEE), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"OPTEE_CLIENT")
	@$(call fetch-git-tree,optee_client)
	@cd optee_client && $(MAKE) -j$(JOBS) ARCH=arm64 && mkdir -p $(DESTDIR)/usr/local/lib && \
	 ln -sf $(DESTDIR)/lib/libteec.so $(DESTDIR)/usr/local/lib/libteec.so && \
	 $(call fbprint_d,"OPTEE_CLIENT")

endif
endif


.PHONY: optee_test
optee_test:
ifeq ($(CONFIG_BUILD_OPTEE), y)
ifeq ($(DESTARCH),arm64)
ifeq ($(CONFIG_BUILD_OPTEE), y)
	@if [ ! -f $(FBDIR)/build/apps/components_arm64/lib/libteec.so.1.0 ]; then \
		$(call fbprint_b,"Optee-client");\
		cd $(FBDIR) && flex-builder -c optee_client -a $(DESTARCH) -m $(MACHINE);\
	fi;
	@$(call fbprint_b,"OPTEE_TEST")
	@$(call fetch-git-tree,optee_test)
	@cd $(FBDIR)/packages/apps/optee_client && $(MAKE) -j$(JOBS) ARCH=arm64;
	@cd optee_test && $(MAKE) CFG_ARM64=y OPTEE_CLIENT_EXPORT=$(FBDIR)/build/apps/components_arm64/ \
	 TA_DEV_KIT_DIR=$(FBDIR)/packages/apps/optee_os/out/arm-plat-ls/export-ta_arm64/
	@if [ ! -d $(FBDIR)/build/apps/components_arm64/lib/optee_armtz ]; then \
		mkdir $(FBDIR)/build/apps/components_arm64/lib/optee_armtz;\
	fi;
	@cp $(FBDIR)/packages/apps/optee_test/out/ta/*/*.ta $(FBDIR)/build/apps/components_arm64/lib/optee_armtz
	@cp $(FBDIR)/packages/apps/optee_test/out/xtest/xtest $(FBDIR)/build/apps/components_arm64/bin
	@$(call fbprint_d,"OPTEE_TEST")
endif
endif
endif


.PHONY: libpkcs11
libpkcs11:
ifeq ($(CONFIG_BUILD_LIBPKCS11), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"libpkcs11")
	@$(call fetch-git-tree,libpkcs11)
	@if [ ! -d $(FBDIR)/packages/apps/openssl ]; then echo building dependent openssl ... && \
	 cd $(FBDIR) && flex-builder -c openssl -f $(CONFIGLIST); fi
	@cd libpkcs11 && $(MAKE) clean && $(MAKE) all OPENSSL_PATH=$(FBDIR)/packages/apps/openssl \
	 EXPORT_DIR=$(DESTDIR)/usr/local CURDIR=$(FBDIR)/packages/apps/libpkcs11 \
	 SECURE_OBJ_PATH=$(FBDIR)/packages/apps/secure_obj/securekey_lib && \
	 mkdir -p $(DESTDIR)/usr/local/bin && \
	 mv $(DESTDIR)/usr/local/app/pkcs11_app $(DESTDIR)/usr/local/bin && \
	 cp -f images/thread_test $(DESTDIR)/usr/bin && $(call fbprint_d,"libpkcs11")
endif
endif


.PHONY: secure_obj
secure_obj:
ifeq ($(CONFIG_BUILD_SECURE_OBJ), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"secure_obj")
	@$(call fetch-git-tree,secure_obj)
	@if [ ! -d $(FBDIR)/packages/apps/openssl ]; then echo building dependent openssl ... && \
	 cd $(FBDIR) && flex-builder -c openssl -f $(CONFIGLIST); fi
	@if [ $(CONFIG_BUILD_OPTEE) != y ]; then \
	     $(call fbprint_e,"Please enable CONFIG_BUILD_OPTEE to y"); exit 1; \
	 fi
	@if [ ! -d $(FBDIR)/packages/apps/optee_os/out/arm-plat-ls ]; then flex-builder -c optee_os; fi
	@if [ ! -f $(DESTDIR)/lib/libteec.so ]; then flex-builder -c optee_client; fi
	@curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
         kerneloutdir=$(FBDIR)/build/linux/$(KERNEL_TREE)/$(DESTARCH)/output/$$curbrch && \
	 if [ ! -f $$kerneloutdir/.config ]; then $(call build_dependent_linux); fi && \
	 kernelrelease=`cat $$kerneloutdir/include/config/kernel.release` && \
	 cd secure_obj && export DESTDIR=${DESTDIR}/usr/local && \
	 export TA_DEV_KIT_DIR=$(FBDIR)/packages/apps/optee_os/out/arm-plat-ls/export-ta_arm64 && \
	 export OPTEE_CLIENT_EXPORT=$(DESTDIR) && export KERNEL_SRC=$(KERNEL_PATH) && \
	 export KERNEL_BUILD=$$kerneloutdir && $(call fbprint_n,"Using KERNEL_BUILD $$kerneloutdir") && \
	 export SECURE_STORAGE_PATH=$(FBDIR)/packages/apps/secure_obj/secure_storage_ta/ta && mkdir -p $(DESTDIR)/usr/lib && \
	 export OPENSSL_PATH=$(FBDIR)/packages/apps/openssl && mkdir -p $(DESTDIR)/usr/local/secure_obj/$$curbrch && \
	 mkdir -p $(DESTDIR)/usr/lib/aarch64-linux-gnu/openssl-1.0.0/engines && mkdir -p $(DESTDIR)/lib/optee_armtz && \
	 ./compile.sh && cp images/libeng_secure_obj.so $(DESTDIR)/usr/lib/aarch64-linux-gnu/openssl-1.0.0/engines && \
	 mkdir -p $(FBDIR)/build/linux/kernel/$(DESTARCH)/lib/modules/$$kernelrelease/extra && \
	 cp images/securekeydev.ko $(FBDIR)/build/linux/kernel/$(DESTARCH)/lib/modules/$$kernelrelease/extra/ && \
	 cp images/*.ta $(DESTDIR)/lib/optee_armtz && cp images/*.so $(DESTDIR)/usr/local/lib && \
	 cp images/{*_app,mp_verify} $(DESTDIR)/usr/local/bin && cp -rf securekey_lib/include/* $(DESTDIR)/usr/local/include && \
	 $(call fbprint_d,"secure_obj")
endif
endif


.PHONY: openssl
openssl:
ifeq ($(CONFIG_BUILD_OPENSSL), y)
	@$(call fbprint_b,"OpenSSL")
	@$(call fetch-git-tree,openssl)
	@if [ ! -d $(DESTDIR)/usr/local/include/crypto ]; then \
	     flex-builder -c cryptodev-linux -a $(DESTARCH) -f $(CONFIGLIST); \
	 fi && \
	 if [ $(DESTARCH) = arm64 ]; then \
	     archopt=linux-aarch64; \
	 elif [ $(DESTARCH) = arm32 ]; then \
	     archopt=linux-armv4; \
	 else \
	     $(call fbprint_e,"$(DESTARCH) is not supported"); exit 1; \
	 fi && \
	 cd openssl && ./Configure -DHAVE_CRYPTODEV -I$(DESTDIR)/usr/local/include \
	 $$archopt shared --prefix=/usr/local --openssldir=lib/ssl && \
	 $(MAKE) clean && $(MAKE) depend && $(MAKE) && \
         $(MAKE) DESTDIR=$(DESTDIR) install && \
         rm -fr $(DESTDIR)/usr/local/lib/ssl/{certs,openssl.cnf,private} && \
         ln -s /etc/ssl/certs/ $(DESTDIR)/usr/local/lib/ssl/ && \
         ln -s /etc/ssl/private/ $(DESTDIR)/usr/local/lib/ssl/ && \
         ln -s /etc/ssl/openssl.cnf $(DESTDIR)/usr/local/lib/ssl/ && \
         $(call fbprint_d,"OpenSSL")
endif


.PHONY: openstack-demo
openstack-demo:
ifeq ($(CONFIG_BUILD_OPENSTACK_DEMO), y)
	@$(call fbprint_b,"OPENSTACK_DEMO")
	@$(call fetch-git-tree,openstack-demo)
	@cd openstack-demo && $(MAKE) && $(call fbprint_d,"OPENSTACK_DEMO")
endif


.PHONY: gpp-aioptool
gpp-aioptool:
ifeq ($(CONFIG_BUILD_GPP_AIOPTOOL), y)
	@$(call fbprint_b,"GPP_AIOPTOOL")
	@$(call fetch-git-tree,gpp-aioptool)
	@cd gpp-aioptool && $(MAKE) clean && $(MAKE) && $(MAKE) install && $(call fbprint_d,"GPP_AIOPTOOL")
endif


.PHONY: qbman_userspace
qbman_userspace:
ifeq ($(CONFIG_BUILD_QBMAN_USERSPACE), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"QBMAN_USERSPACE")
	@$(call fetch-git-tree,qbman_userspace)
	@cd qbman_userspace && export PREFIX=/usr/local && export ARCH=aarch64 && \
	 $(MAKE) && $(MAKE) install && $(call fbprint_d,"QBMAN_USERSPACE")
endif
endif


.PHONY: eth-config
eth-config:
ifeq ($(CONFIG_BUILD_ETH_CONFIG), y)
	@$(call fbprint_b,"ETH_CONFIG")
	@$(call fetch-git-tree,eth-config)
	@mkdir -p $(DESTDIR)/etc/fmc/config
	@cd eth-config && cp -rf private $(DESTDIR)/etc/fmc/config && \
	 cp -rf shared_mac $(DESTDIR)/etc/fmc/config && $(call fbprint_d,"ETH_CONFIG")
endif


.PHONY: ptpd
ptpd:
ifeq ($(CONFIG_BUILD_PTPD), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"PTPd")
	@$(call fetch-git-tree,ptpd)
	@if [ $(DESTARCH) = arm64 ]; then host=aarch64-linux-gnu; else host=arm-linux-gnueabihf; fi && \
	 if [ ! -f $(RFSDIR)/lib/$$host/libpcap.so ]; then $(call build_dependent_rfs); fi && \
	 if [ $(DESTARCH) = arm32 ]; then export CROSS_COMPILE=arm-linux-gnueabihf-; fi && \
	 cd ptpd && export LDFLAGS="-L$(RFSDIR)/lib/$$host" && autoreconf -vi && \
	 ./configure --host=$$host ac_cv_func_malloc_0_nonnull=yes && $(MAKE) && $(MAKE) install && $(call fbprint_d,"PTPd")
endif
endif


.PHONY: crconf
crconf:
ifeq ($(CONFIG_BUILD_CRCONF), y)
	@$(call fbprint_b,"CRONF")
	@$(call fetch-git-tree,crconf)
	@if [ -d code -a ! -d crconf ]; then mv code crconf; fi
	@sed -i -e 's/CC =/CC ?=/' -e 's/DESTDIR=/DESTDIR?=/' crconf/Makefile
	@cd crconf && export CC=$(CROSS_COMPILE)gcc && export DESTDIR=${DESTDIR}/usr/local && \
	 $(MAKE) clean && $(MAKE) && $(MAKE) install && $(call fbprint_d,"CRONF")
endif

.PHONY: iperf
iperf:
ifeq ($(CONFIG_BUILD_IPERF), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"IPERF")
	@$(call fetch-git-tree,iperf)
	@if [ -d code -a ! -d iperf ]; then mv code iperf; fi
	@cd iperf && \
         export CC=aarch64-linux-gnu-gcc && \
         export CXX=aarch64-linux-gnu-g++ && \
         ./configure --host=aarch64 && \
         make && sudo make install DESTDIR=${DESTDIR}
	@$(call fbprint_d,"IPERF")
endif
endif


edgescale: qoriq-edgescale-eds qoriq-eds-kubelet qoriq-eds-bootstrap

.PHONY: qoriq-edgescale-eds
qoriq-edgescale-eds:
ifeq ($(CONFIG_BUILD_QORIQ_EDGESCALE), y)
	@$(call fetch-git-tree,qoriq-edgescale-eds)
	@if [ $(DESTARCH) = arm32 ]; then arch=arm; \
         elif [ $(DESTARCH) = arm64 ]; then arch=arm64; \
         else echo $(DESTARCH) is unsupported in edgescale-eds; exit 0; \
         fi && \
	 if [ $(CONFIG_EDGESCALE_SECURE_MODE) = y ]; then \
	     $(call fbprint_n,"Edgescale secure mode enabled") && \
	     if [ $(DESTARCH) != arm64 ]; then \
	         echo $(DESTARCH) is not supported yet for EdgeScale secure mode; exit 0; \
	     fi && \
	     if [ $(CONFIG_BUILD_OPTEE) = n ]; then \
		 $(call fbprint_e,"Please enable CONFIG_BUILD_OPTEE to y"); exit 1; \
	     fi && \
	     if [ ! -f $(DESTDIR)/lib/libteec.so ]; then \
		 echo dependent libteec.so not exist, building it ... && flex-builder -c secure_obj -f $(CONFIGLIST); \
	     fi && \
	     if [ ! -d $(DESTDIR)/usr/local/include/openssl ]; then \
		 echo dependent openssl not exist, building it ... && flex-builder -c openssl -f $(CONFIGLIST); \
	     fi && \
	     cd qoriq-edgescale-eds && $(MAKE) -j$(JOBS) ARCH=$$arch OPENSSL_PATH=$(DESTDIR)/usr/local \
	     SECURE_OBJ_PATH=$(DESTDIR)/usr/local OPTEE_CLIENT_EXPORT=$(DESTDIR)/lib GOBUILDTAGS=secure; \
	 else \
	     $(call fbprint_b,"Edgescale secure mode not enabled") && \
	     cd qoriq-edgescale-eds && $(MAKE) -j$(JOBS) ARCH=$$arch OPENSSL_PATH=$(DESTDIR)/usr/local \
	     SECURE_OBJ_PATH=$(DESTDIR)/usr/local OPTEE_CLIENT_EXPORT=$(DESTDIR)/lib; \
         fi && \
         $(MAKE) install INSTALL_DIR=$(RFSDIR) ARCH=$$arch && \
	 $(call fbprint_d,"qoriq-edgescale-eds")
else
	$(call fbprint_n,"CONFIG_BUILD_QORIQ_EDGESCALE is not enabled by default in $(CONFIGLIST)")
endif


.PHONY: qoriq-eds-kubelet
qoriq-eds-kubelet:
ifeq ($(CONFIG_BUILD_QORIQ_EDGESCALE), y)
	@$(call fbprint_b,"qoriq-eds-kubelet")
	@$(call fetch-git-tree,qoriq-eds-kubelet)
	@if [ $(DESTARCH) = arm32 ]; then arch=arm; elif [ $(DESTARCH) = arm64 ]; then arch=arm64; else \
	 echo $(DESTARCH) is unsupported in eds-kubelet; exit 0; fi && \
	 cd qoriq-eds-kubelet && $(MAKE) ARCH=$$arch && $(MAKE) install INSTALL_DIR=$(RFSDIR) ARCH=$$arch && \
	 $(call fbprint_d,"qoriq-eds-kubelet")
endif

.PHONY: qoriq-eds-bootstrap
qoriq-eds-bootstrap:
ifeq ($(CONFIG_BUILD_QORIQ_EDGESCALE), y)
	@$(call fbprint_b,"qoriq-eds-bootstrap")
	@$(call fetch-git-tree,qoriq-eds-bootstrap)
	@if [ $(DESTARCH) = arm32 ]; then arch=arm; elif [ $(DESTARCH) = arm64 ]; then  arch=arm64; else \
	 echo $(DESTARCH) is unsupported in eds-bootstrap; exit 0; fi && \
	 cd qoriq-eds-bootstrap && $(MAKE) install INSTALL_DIR=$(DESTDIR) ARCH=$$arch && $(call fbprint_d,"qoriq-eds-bootstrap")
endif

.PHONY: optee_ta_ftpm
optee_ta_ftpm:
ifeq ($(CONFIG_BUILD_OPTEE), y)
ifeq ($(CONFIG_BUILD_OPTEE_TA_FTPM), y)
ifeq ($(DESTARCH),arm64)
	@$(call fbprint_b,"optee_ta_ftpm")
	@$(call fetch-git-tree,ftpm)
	cd ftpm/Samples/ARM32-FirmwareTPM/optee_ta && git submodule init && git submodule update && \
	TA_CPU=cortex-a53 TA_CROSS_COMPILE=$(CROSS_COMPILE) TA_DEV_KIT_DIR=$(FBDIR)/packages/apps/optee_os/out/arm-plat-ls/export-ta_arm64/ $(MAKE) && \
	mkdir -p $(DESTDIR)/lib/optee_armtz && \
	cp out/fTPM/bc50d971-d4c9-42c4-82cb-343fb7f37896.ta $(DESTDIR)/lib/optee_armtz/ && \
	$(call fbprint_d,"optee_ta_ftpm")
endif
endif
endif


repo_fetch:
	@echo -e "\nfetch apps repositories ..."
	@$(call repo-update,fetch,$(APPS_REPO_LIST))

repo_update_branch:
	@echo -e "\napps repositories update for branch ..."
	@$(call repo-update,branch,$(APPS_REPO_LIST))

repo_update_tag:
	@echo -e "\napps repositories update for tag ..."
	@$(call repo-update,tag,$(APPS_REPO_LIST))

repo_update_latest:
	@echo -e "\napps repositories update to latest HEAD commit ..."
	@$(call repo-update,update,$(APPS_REPO_LIST))

repo_update_commit:
	@echo -e "\napps repositories update to specified commit ID ..."
	@$(call repo-update,commit,$(APPS_REPO_LIST))
