# leap — kernel + modules + DTB from source (D45); included by BoardConfig.mk.
# Sources: kernel/motorola/sm8750 (MotorolaMobilityLLC/kernel-msm @ MMI-W1VLS36H.59-55-5-1, 6.6.82),
#   sm8750-modules (LOS oneplus/qcom-generic techpack copies + Motorola's audio/camera/wlan/motorola modules),
#   sm8750-devicetrees (kernel-devicetree @ tag) linked at arch/arm64/boot/dts/vendor.

TARGET_KERNEL_SOURCE := kernel/motorola/sm8750
TARGET_KERNEL_VERSION := 6.6
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    vendor/sun_perf.config \
    vendor/ext_config/moto-sun.config \
    vendor/ext_config/moto-sun-leap.config
TARGET_KERNEL_CONFIG_EXT := $(DEVICE_PATH)/kernel/leap-los.config
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_USES_GENERIC_KERNEL_IMAGE := true

# CONFIG_DRM_DYNAMIC_REFRESH_RATE=y (D60): our msm_drm exports dsi_freq_head, so the touch drivers follow the panel
# refresh rate. It is a module-build variable only; kernel/leap-los.config keeps it unset in the kernel image.
# clang 21 vs a 6.6.82 tree with CONFIG_WERROR=y; Motorola's kbuild needs the OEM DTB switch, the SoC switch,
# the profile-derived WLAN configs bazel would resolve, and the stub include root for moto-kernel-modules.
# NOTE: no comments inside the continued assignment — a "#" swallows the trailing backslash and silently drops the
# rest of the flags (that hid the touch-driver options for three builds). Motorola Kbuilds default ANDROID_BUILD_TOP to
# $(srctree)/.. = kernel/motorola, where motorola/kernel/modules and kernel_platform/* are symlinks.
TARGET_KERNEL_ADDITIONAL_FLAGS := \
    KCFLAGS="-Wno-unknown-warning-option -Wno-default-const-init-unsafe -Wno-error=missing-prototypes -Wno-missing-prototypes -Wno-error=format -Wno-error=enum-compare -Wno-error=enum-compare-conditional -Wno-error=unused-but-set-variable -Wno-error=unused-variable -Wno-error=unused-function" \
    CONFIG_MMI_DEVICE_DTBS=y TARGET_BOARD_PLATFORM=sun CONFIG_ARCH_SUN=y \
    CONFIG_WLAN_TELEMETRY=n CONFIG_WLAN_TX_MON_2_0=y QCA_WIFI_FTM_NL80211=y \
    CONFIG_DRM_PANEL_EVENT_NOTIFICATIONS=y CONFIG_DRM_DYNAMIC_REFRESH_RATE=y CONFIG_BOARD_USES_DOUBLE_TAP_CTRL=y CONFIG_INPUT_TOUCHSCREEN_MMI=y CONFIG_TOUCHSCREEN_GOODIX_BRL_SPI=y CONFIG_BUILD_FOR_ANDROID_V=y GKI_OBJ_MODULE_DIR=

TARGET_KERNEL_EXT_MODULE_ROOT := kernel/motorola/sm8750-modules
# Motorola entries are dependency-ordered (sensors/mmi_relay/mmi_info/bm_adsp_ulog first: hall, glink charger, touch need their Module.symvers)
TARGET_KERNEL_EXT_MODULES := \
    qcom/opensource/mmrm-driver \
    qcom/opensource/mm-drivers/hw_fence \
    qcom/opensource/mm-drivers/msm_ext_display \
    qcom/opensource/mm-drivers/sync_fence \
    qcom/opensource/audio-kernel \
    qcom/opensource/securemsm-kernel \
    qcom/opensource/synx-kernel \
    qcom/opensource/camera-kernel \
    qcom/opensource/data-kernel/drivers/smem-mailbox \
    qcom/opensource/datarmnet-ext/mem \
    qcom/opensource/dataipa/drivers/platform/msm \
    qcom/opensource/datarmnet/core \
    qcom/opensource/datarmnet-ext/aps \
    qcom/opensource/datarmnet-ext/offload \
    qcom/opensource/datarmnet-ext/perf \
    qcom/opensource/datarmnet-ext/perf_tether \
    qcom/opensource/datarmnet-ext/sch \
    qcom/opensource/datarmnet-ext/shs \
    qcom/opensource/datarmnet-ext/wlan \
    qcom/opensource/display-drivers/msm \
    qcom/opensource/dsp-kernel \
    qcom/opensource/eva-kernel \
    qcom/opensource/graphics-kernel \
    qcom/opensource/spu-kernel \
    qcom/opensource/video-driver \
    qcom/opensource/wlan/platform \
    qcom/opensource/wlan/qcacld-3.0 \
    qcom/opensource/bt-kernel \
    motorola/drivers/sensors:kbuild \
    motorola/drivers/mmi_relay:kbuild \
    motorola/drivers/mmi_annotate:kbuild \
    motorola/drivers/mmi_info:kbuild \
    motorola/drivers/power/bm_adsp_ulog:kbuild \
    motorola/drivers/power/mmi_glink_charger/qti_glink_charger_v2:kbuild \
    motorola/drivers/ese/st54spi_gpio:kbuild \
    motorola/drivers/input/misc/fpc_fps_mmi:kbuild \
    motorola/drivers/misc/hall:kbuild \
    motorola/drivers/misc/mmi_sys_temp:kbuild \
    motorola/drivers/moto_binder:kbuild \
    motorola/drivers/moto_f_usbnet:kbuild \
    motorola/drivers/moto_mmap_fault:kbuild \
    motorola/drivers/moto_netopt/con_dfpar:kbuild \
    motorola/drivers/moto_pm_vh:kbuild \
    motorola/drivers/moto_reboot_reason:kbuild \
    motorola/drivers/moto_sched:kbuild \
    motorola/drivers/nfc/mmi_nfc_clk:kbuild \
    motorola/drivers/nfc/st21nfc:kbuild \
    motorola/drivers/power/mmi_glink_charger:kbuild \
    motorola/drivers/security/moto_kern_prot:kbuild \
    motorola/drivers/watchdogtest:kbuild \
    motorola/drivers/misc/sx937x_multi:kbuild \
    motorola/drivers/input/touchscreen/touchscreen_mmi:kbuild \
    motorola/drivers/input/touchscreen/goodix_berlin_mmi:kbuild \
    motorola/drivers/input/touchscreen/focaltech_touch_v3_5:kbuild \
    motorola/drivers/uwb/qm358:kbuild \
    motorola/drivers/misc/utag:kbuild

# stock names for the three Motorola modules whose source names differ
TARGET_MODULE_ALIASES := \
    snd-soc-tfa98xx.ko:tfa98xx_dlkm.ko \
    st21nfc.ko:stm_nfc_i2c.ko \
    st54spi_gpio.ko:stm_st54se_gpio.ko

# Module placement = stock's load lists (names identical). Modules not in any list land in vendor_dlkm.
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.vendor_ramdisk.src))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.recovery.src))
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(DEVICE_PATH)/modules.load.src))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(DEVICE_PATH)/modules.blocklist
BOOT_KERNEL_MODULES := $(BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD)
SYSTEM_KERNEL_MODULES := $(strip $(shell cat $(DEVICE_PATH)/modules.load.system_dlkm.src))

# DTB/DTBO from source (sun-tp[-v2]-leap-base + sun-leap-evb/evt1/pvt1 overlays)
BOARD_USES_QCOM_MERGE_DTBS_SCRIPT := true

# D53: ship only the two base DTBs stock ships (sun-tp-leap-base, sun-tp-v2-leap-base), merged with the techpack
# overlays by merge_dtbs.py (merged output keeps the base name). Pattern must END at -leap-base: Moto's Makefile also
# emits pre-combined <base>-<board-overlay>.dtb files which sort FIRST and ABL would pick them (same ids) and then apply
# the dtbo board overlay a second time on top of the wrong board variant.
TARGET_MERGE_DTBS_WILDCARD := sun-tp*-leap-base

# D53: build the kernel with the toolchain Moto's tree pins (build.config.constants: CLANG_VERSION=r510928, clang 18 —
# the same compiler the shipped GKI 6.6.118 reports). Our clang-21 build of 6.6.82 started and panicked in first stage.
TARGET_KERNEL_CLANG_PATH := /home/kali/Desktop/RAZRULTRA2025LINEAGEROM/refs/clang/clang-r510928
