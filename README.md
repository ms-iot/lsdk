Flexbuild Overview
---------------------------------------------------------------------------------
	Flexbuild is a component-oriented build framework and integrated platform
	with capabilities of flexible, ease-to-use, scalable system build and
	distro installation. With flex-builder CLI, users can build various
	components (linux, u-boot, uefi, rcw, ppa and miscellaneous custom
	userspace applications) and distro userland to generate composite
	firmware, hybrid rootfs with customable userland.



Supported Arch
--------------------------------------------------------------------------------
	ARM32(LE), ARM64(LE), ARM32(BE)
	ARM64(BE), PPC32(BE), PPC64(BE)


Supported Distros
-------------------------------------------------------------------------------
	Ubuntu  (default for LSDK with full system test)
	Debian  (optional, basic bootup test)
	CentOS  (optional, basic bootup test)
	Buildroot-based Tiny Distro (optional)


Build Environment
-------------------------------------------------------------------------------
	Cross-build on Ubuntu x86 host
	Native-build on Ubuntu ARM board
	Build in Docker hosted on any machine


Supported ARM Platforms
-------------------------------------------------------------------------------
	LS1012ARDB, LS1012AFRWY, LS1021ATWR,  LS1043RDB, LS1046ARDB
	LS1088ARDB,  LS2088RDB, etc


Supported PPC Platforms
-------------------------------------------------------------------------------
	T1024ARDB, T2080RDB, T4240RDB, etc




Users can choose the appropriate userland from various Ubuntu (default), Debian or
Buildroot-based tiny distro (optional) to adapt the needs in practic use case.


See docs/flexbuild_usage.txt and docs/lsdk_build_install.txt for detailed information.
