#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# BoardConfig for Motorola Razr Ultra 2025 (leap) — SKELETON DRAFT
#
# Provenance key (do not remove until each line is confirmed):
#   [D]  = mirrored from device/oneplus/sm8750-common (dodge, same SoC, read 2026-08-24)
#   [M]  = Motorola idiom from device/motorola/sm8475-common / device_zeekr
#   [H]  = handoff-verified fact
#   TODO(<source>) = UNVERIFIED — must come from that source before first build/flash
#

DEVICE_PATH := device/motorola/leap

# A/B                                                                     [D]
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    init_boot \
    product \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm
# VERIFIED: gpt.bin shows recovery_a/recovery_b + a 128 MiB recovery.img in the package →
# dodge-style dedicated recovery partition (not recovery-as-boot). `recovery` included above.
# RESOLVED on device 2026-09-19: leap has NO odm and NO vbmeta_vendor partition (verified by
# `ls /dev/block/by-name/` on the real unit). Both were inherited from dodge and both broke the
# OTA: update_engine aborted with "Device file /dev/block/bootdevice/by-name/odm_a does not
# exist" -> kInstallDeviceOpenError(7). vendor/vendor_dlkm are now chained into the MAIN vbmeta.

# Architecture                                                            [D]
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := oryon

# Bootloader                                                              [M]
TARGET_BOOTLOADER_BOARD_NAME := leap
TARGET_BOARD_PLATFORM := sun
BOARD_USES_QCOM_HARDWARE := true

# Boot — GKI split: boot=kernel, init_boot=generic ramdisk,
# vendor_boot=vendor ramdisk+DLKM                                         [H][D]
# VERIFIED: boot/init_boot/vendor_boot all header v4 in stock A15 package.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)
BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_IMAGE_NAME := Image

# DTB / DTBO                                                              [D]
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
# D59: stock dtbo — it carries the whole display subsystem (Motorola's panel DT is unpublished) and is what every
# source-kernel build since D53 was flashed with; `dtbo` is in AB_OTA_PARTITIONS, so the OTA needs it.
BOARD_PREBUILT_DTBOIMAGE := device/motorola/leap/prebuilts/dtbo.img

# Kernel + modules + DTB, all from source (D45): see BoardConfigKernelSource.mk.
include $(DEVICE_PATH)/BoardConfigKernelSource.mk
# ---------------------------------------------------------------------------------------------

# Kernel bootconfig/cmdline — VERIFIED verbatim from stock A15 vendor_boot.img
BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.hypervisor.protected_vm.supported=true \
    androidboot.load_modules_parallel=true \
    androidboot.memcg=1 \
    androidboot.serialconsole=0 \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.vendor.qspa=true \
    androidboot.init_fatal_panic=true
# ^^^ androidboot.init_fatal_panic=true is TEMPORARY DEBUG (remove before any release).
# system/core/init/reboot_utils.cpp:50-57 reads it from bootconfig OR cmdline. Default behaviour
# on a first-stage fatal error is a CLEAN reboot to the bootloader, which leaves no crash record
# (this is why pstore and kpan were empty every time). With this set init calls panic() instead,
# so ramoops captures init's actual error message. ramoops is confirmed working on this device:
#   OF: reserved mem: 0xae000000..0xae05ffff (384 KiB) ramoops_region
#   pstore: Registered ramoops as persistent store backend
# BRING-UP ONLY: run SELinux permissive so a missing/incomplete sepolicy domain cannot stop a
# vendor service from starting or a HAL from registering (every failure so far was silent;
# permissive turns the whole class into logcat 'avc: denied' lines instead of hangs).
# Honoured on userdebug: system/core/init/selinux.cpp:104 reads androidboot.selinux from the
# kernel cmdline, gated by ALLOW_PERMISSIVE_SELINUX=1 (init/Android.bp:147, debuggable).
# REMOVE before any release build.
BOARD_KERNEL_CMDLINE := \
    video=vfb:640x400,bpp=32,memsize=3072000 \
    console=ttynull \
    qcom_geni_serial.con_enabled=0 \
    nosoftlockup \
    pstore.compress=none \
    printk.devkmsg=on \
    mem.enable_mglru=1 \
    firmware_class.path=/vendor/firmware_mnt/image
# `video=vfb:...` restored 2026-09-19: diffing our vendor_boot cmdline against stock's showed it
# was the ONLY divergence (bootconfig matched exactly, boot.img cmdline empty on both).
# LOS appends the trailing `bootconfig` token itself.

# Metadata                                                                [D]
BOARD_USES_METADATA_PARTITION := true

# Partitions — boot-critical sizes VERIFIED from leap gpt.bin (4096-byte sectors).
# These are capacity-INVARIANT (same on the 1 TB unit) and happen to match dodge.
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296        # 96 MiB (VERIFIED gpt boot_a)
BOARD_DTBOIMG_PARTITION_SIZE := 25165824           # 24 MiB (VERIFIED gpt dtbo_a)
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608    # 8 MiB  (VERIFIED gpt init_boot_a)
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296 # 96 MiB (VERIFIED gpt vendor_boot_a)
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 134217728    # 128 MiB (VERIFIED gpt recovery_a)
#
# super — values VERIFIED from LP metadata of the A15 RETUS package (lpunpack.py --list):
#   super size 26481786880, group mot_dp_group_a/_b = 26477592576 (= super - 4 MiB exactly),
#   6 logical partitions, NO odm (folded into vendor).
# ⚠️ HARD RULE: 1 TB SKU layout is a known brick vector. super size is usually capacity-invariant
# (userdata absorbs the difference) so these likely hold on the 1 TB unit — but CONFIRM with
# `lpdump` on the user's OWN device before building/flashing.
BOARD_SUPER_PARTITION_SIZE := 26481786880
BOARD_MOT_DP_GROUP_SIZE := 26477592576
BOARD_SUPER_PARTITION_GROUPS := mot_dp_group
BOARD_MOT_DP_GROUP_PARTITION_LIST := product system system_dlkm system_ext vendor vendor_dlkm
BOARD_FLASH_BLOCK_SIZE := 262144

# Filesystems                                                             [D]
# (no BOARD_ODMIMAGE_FILE_SYSTEM_TYPE: no odm image is built — odm ships inside vendor)
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_ODM := vendor/odm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Recovery                                                                [D]
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.default
# TODO: fstab.default transcribed from stock (start from sm8750-common/init/fstab.default,
# swap oplus nodes for Moto's).
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# HIDL / ODM SKUs                                                         [M]
# leap SKU suffixes VERIFIED via strings on vendor_a.img
# (ro.vendor.product.name.suffix): n nc nq q s sn t uw.
# TODO(erofs extract vendor vhw.xml + manifests): map each suffix → its manifest file,
# mirror zeekr's ODM_MANIFEST_SKUS/ODM_MANIFEST_*_FILES wiring. Draft:
# ODM_MANIFEST_SKUS += n nc nq q s sn t uw

# Properties
TARGET_ODM_PROP += $(DEVICE_PATH)/odm.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Security patch — VERIFIED from vendor build.prop (A16 pkg W1VLS36H.59-128-4-6, D35).
# ro.vendor.build.security_patch=2026-06-01 (stock A16 boot.img carries no os_version at all).
VENDOR_SECURITY_PATCH := 2026-06-01
BOOT_SECURITY_PATCH := 2026-08-01   # D53: must never go DOWN — Keymaster persists the highest boot patch level it has seen (RPMB); a lower value = FBE keys refused = init_user0_failed = wipe prompt. Source-kernel path stamped 2026-08 on 09-28.
# (boot.img SPL may differ slightly; confirm with avbtool/bootimg header when rebasing to A16.)

# SEPolicy                                                                [D→M]
include device/qcom/sepolicy_vndr/SEPolicy.mk
# D42: dropped — LOS generic Moto policy renames stock types; stock policy is harvested into sepolicy/vendor-moto instead
#include hardware/motorola/sepolicy/qti/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
# D37: Motorola domains harvested from stock A16 vendor_sepolicy.cil (tools/cil2te.py) — generated, do not hand-edit
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor-moto

# Verified Boot                                                           [D]
# Device cannot be relocked (Motorola) — test keys are permanent; --flags 3 disables
# verity+verification exactly as dodge does.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 4
BOARD_AVB_DTBO_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_DTBO_ALGORITHM := SHA256_RSA4096
BOARD_AVB_DTBO_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_DTBO_ROLLBACK_INDEX_LOCATION := 3
BOARD_AVB_VBMETA_SYSTEM := system system_dlkm system_ext product
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2
# (no BOARD_AVB_VBMETA_VENDOR: the device has no vbmeta_vendor partition, so vendor and
#  vendor_dlkm descriptors go into the main vbmeta image instead.)
BOARD_AVB_VENDOR_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VENDOR_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 6
# TODO(avbtool info_image on stock vbmeta*): confirm index locations + live rollback indexes;
# zeekr pins BOARD_AVB_ROLLBACK_INDEX explicitly (26) — leap's value from stock.

# WiFi                                                                    [D]
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := $(BOARD_HOSTAPD_DRIVER)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := $(BOARD_HOSTAPD_PRIVATE_LIB)
BOARD_WPA_SUPPLICANT_PRIVATE_LIB_EVENT := "ON"
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_FEATURE_HOSTAPD_11AX := true
WIFI_HIDL_FEATURE_AWARE := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# Proprietary — generated by extract-utils
include vendor/motorola/leap/BoardConfigVendor.mk

# FS config — custom vendor AIDs (QTI 2901-2917 from dodge + Moto tcmd 5104); needed by
# host_init_verifier for stock vendor init .rc files              [D][M]
TARGET_FS_CONFIG_GEN := device/motorola/leap/config.fs

# VINTF — Moto ships SKU manifests, not manifest.xml: vendor/etc/vintf/manifest_sun.xml
# (sun = SM8750; kera/tuna = other devices sharing the vendor build). Declaring the SKU
# makes check_vintf validate manifest_sun.xml; runtime selection via ro.boot.product.vendor.sku
# set by ABL.                                                              [stock dump]
# NOTE: BOARD_SEPOLICY_VERS is NOT settable on Android 16 — config.mk:881 forces it to
# PLATFORM_SEPOLICY_VERSION and marks it .KATI_READONLY (vendor sepolicy skew removed).

DEVICE_MANIFEST_SKUS := sun
DEVICE_MANIFEST_SUN_FILES := $(DEVICE_PATH)/manifests/manifest_sun.xml


# TEMPORARY (D16-c): enumerate every duplicate install rule in one kati pass; remove once fixed.
BUILD_BROKEN_DUP_RULES := true

# D16-c: display namespaces. BoardConfigQcom.mk exports vendor/qcom/opensource/{commonsys-intf/,}display
# to make; leap's display stack is 100% stock blobs (A15) and the A16-generated display AIDL libs are
# ABI-incompatible with them (findings.md D16-c: PAC/autiasp SIGILL in libsdmclient). Hiding the source
# interfaces from make lets the stock libs install under their real names (D15k audio-tree pattern).
TARGET_HIDE_QCOM_DISPLAY_NAMESPACES := true
