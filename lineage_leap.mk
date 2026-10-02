#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from leap device
$(call inherit-product, device/motorola/leap/device.mk)

PRODUCT_DEVICE := leap
PRODUCT_NAME := lineage_leap
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola razr ultra 2025
PRODUCT_MANUFACTURER := motorola

PRODUCT_GMS_CLIENTID_BASE := android-motorola

# Match the stock system product name so the build fingerprint lines up with
# the vendor blobs (stock product = leap_g; codename/device = leap).
# A16/soong gen_build_prop takes camel-case product_config keys (old TARGET_DEVICE=/
# PRODUCT_NAME= idiom is rejected). DeviceName is already 'leap'; only the product
# name needs overriding so the fingerprint matches stock
# (device reports: motorola/leap_guuw/leap:15/V2VL35.42-148-2/5fe0b-a110b2:user/release-keys).
PRODUCT_BUILD_PROP_OVERRIDES += \
    DeviceProduct=leap_guuw

# Inherit from the common Lineage configuration.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
