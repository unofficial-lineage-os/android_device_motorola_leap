#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/motorola/leap

# A/B
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
# leap has dedicated recovery partitions, and no odm or vbmeta_vendor partition.

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := oryon

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := leap
TARGET_BOARD_PLATFORM := sun
BOARD_USES_QCOM_HARDWARE := true

# Boot
BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_INIT_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_INIT_ARGS += --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)
BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_IMAGE_NAME := Image

# DTB / DTBO
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
# Stock dtbo: it carries the display subsystem, and Motorola does not publish the panel device trees.
BOARD_PREBUILT_DTBOIMAGE := device/motorola/leap/prebuilts/dtbo.img

# Kernel
include $(DEVICE_PATH)/BoardConfigKernelSource.mk

BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.hypervisor.protected_vm.supported=true \
    androidboot.load_modules_parallel=true \
    androidboot.memcg=1 \
    androidboot.serialconsole=0 \
    androidboot.usbcontroller=a600000.dwc3 \
    androidboot.vendor.qspa=true

BOARD_KERNEL_CMDLINE := \
    video=vfb:640x400,bpp=32,memsize=3072000 \
    console=ttynull \
    qcom_geni_serial.con_enabled=0 \
    nosoftlockup \
    pstore.compress=none \
    printk.devkmsg=on \
    mem.enable_mglru=1 \
    firmware_class.path=/vendor/firmware_mnt/image

# Metadata
BOARD_USES_METADATA_PARTITION := true

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296        # 96 MiB
BOARD_DTBOIMG_PARTITION_SIZE := 25165824           # 24 MiB
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608    # 8 MiB
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296 # 96 MiB
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 134217728    # 128 MiB

BOARD_SUPER_PARTITION_SIZE := 26481786880
BOARD_MOT_DP_GROUP_SIZE := 26477592576
BOARD_SUPER_PARTITION_GROUPS := mot_dp_group
BOARD_MOT_DP_GROUP_PARTITION_LIST := product system system_dlkm system_ext vendor vendor_dlkm
BOARD_FLASH_BLOCK_SIZE := 262144

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

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.default
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# Properties
TARGET_ODM_PROP += $(DEVICE_PATH)/odm.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Security patch
VENDOR_SECURITY_PATCH := 2026-06-01
# Never lower this: Keymaster keeps the highest boot patch level it has seen and refuses
# the user's keys on a lower one.
BOOT_SECURITY_PATCH := 2026-08-01

# SEPolicy
include device/qcom/sepolicy_vndr/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
# Motorola's vendor policy, converted from the stock vendor_sepolicy.cil.
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor-moto

# Verified Boot
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
BOARD_AVB_VENDOR_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VENDOR_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 6

# WiFi
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

# Inherit from the proprietary version
include vendor/motorola/leap/BoardConfigVendor.mk

# FS config
TARGET_FS_CONFIG_GEN := device/motorola/leap/config.fs

# VINTF
DEVICE_MANIFEST_SKUS := sun
DEVICE_MANIFEST_SUN_FILES := $(DEVICE_PATH)/manifests/manifest_sun.xml

# Display
# The display HAL and its clients are stock blobs. Keep Qualcomm's source display interfaces
# out of make so they do not replace the libraries those blobs were built against.
TARGET_HIDE_QCOM_DISPLAY_NAMESPACES := true
