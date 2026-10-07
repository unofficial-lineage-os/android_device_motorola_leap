#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/motorola/leap

# Qualcomm common
$(call inherit-product, hardware/qcom-caf/common/common.mk)

# Virtual A/B
# Stock enables userspace snapshots with XOR compression, which needs snapuserd in the vendor ramdisk.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)
PRODUCT_VENDOR_PROPERTIES += ro.virtual_ab.compression.threads=true

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# VINTF
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    device/motorola/leap/vintf/device_framework_matrix.xml \
    hardware/motorola/vintf/device_framework_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API levels
PRODUCT_SHIPPING_API_LEVEL := 35

# Boot animation
TARGET_SCREEN_HEIGHT := 2992
TARGET_SCREEN_WIDTH := 1224

# Fold
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/fold/device_state_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/devicestate/device_state_configuration.xml \
    $(DEVICE_PATH)/fold/display_layout_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_layout_configuration.xml \
    $(DEVICE_PATH)/fold/display_id_4630947043778501779.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947043778501779.xml \
    $(DEVICE_PATH)/fold/display_id_4630947043778501780.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947043778501780.xml

# Overlays
PRODUCT_PACKAGES += \
    LeapFrameworksResOverlay \
    LeapSystemUIOverlay \
    LeapApertureOverlay

# NFC
PRODUCT_PACKAGES += \
    Tag

# Sensors
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.hinge_angle.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hinge_angle.xml

# LiveDisplay
PRODUCT_PACKAGES += \
    vendor.lineage.livedisplay-service.leap

# Init
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init/vndservicemanager.leap.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vndservicemanager.leap.rc \
    $(DEVICE_PATH)/init/init.leap.touch-gesture.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.leap.touch-gesture.rc

# Boot animation on both displays. Drawing on the cover display powers it on, so it turns off
# properly once boot completes.
$(call soong_config_set_bool,bootanimation,multidisplay,true)

# WiFi
PRODUCT_PACKAGES += \
    leap_wlan_symlink_qcom_cfg \
    leap_wlan_symlink_prc_cfg \
    leap_wlan_symlink_mac

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(DEVICE_PATH)/overlay \
    $(DEVICE_PATH)/overlay-lineage \
    $(DEVICE_PATH)/overlay-static
# Launcher3's device profiles use the app's private attributes, so they cannot be an RRO.
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += $(DEVICE_PATH)/overlay-static
PRODUCT_ENFORCE_RRO_TARGETS := *

# Display
PRODUCT_PACKAGES += \
    init.qti.display_boot.rc \
    qspa_vendor.rc

# Data
PRODUCT_PACKAGES += \
    IPACM_cfg.xml \
    IPACM_Filter_cfg.xml

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey.xml

# Permissions
PRODUCT_PACKAGES += \
    android.hardware.hardware_keystore.xml \
    features_com.android.virt.xml

# Boot control
# Qualcomm's HAL: the bootloader reads the slot state from the GPT attributes, not from misc.
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

# Fastboot
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.example_recovery \
    fastbootd

# Update engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)

# Init
PRODUCT_PACKAGES += \
    fstab.default \
    fstab.default.vendor_ramdisk \
    init.qcom.recovery.rc

PRODUCT_PACKAGES += \
    init.mmi.charge_only.rc \
    init.mmi.chipset.rc \
    init.mmi.debug.rc \
    init.mmi.diag.rc \
    init.mmi.diag_mdlog.rc \
    init.mmi.graphics.rc \
    init.mmi.overlay.rc \
    init.mmi.rc \
    init.mmi.tcmd.rc \
    init.mmi.usb.rc \
    init.mmi.wlan.rc \
    init.qcom.factory.rc \
    init.qcom.rc \
    init.qti.kernel.rc \
    init.qti.kernel.target.rc \
    init.qti.ufs.rc \
    init.target.rc \
    init.vendor.st21nfc.rc

# WiFi
# libwifi-hal-qcom here is the source library. The stock one, which hal_proxy_daemon links,
# ships as libwifi-hal-qcom-vendor.so.
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf

# Sensors
PRODUCT_PACKAGES += \
    android.hardware.sensors-service.multihal \
    android.hardware.drm-service.clearkey

# Tethering offload
PRODUCT_PACKAGES += \
    ipacm

# Vibrator
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service

# Audio
# Stock configurations whose file names match source modules, so they cannot come from the blob list.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/sku_sun/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/audio_policy_configuration.xml \
    $(DEVICE_PATH)/configs/audio/sku_sun/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/audio_effects.xml \
    $(DEVICE_PATH)/configs/audio/sku_sun/vendor_audio_interfaces.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/vendor_audio_interfaces.xml \
    $(DEVICE_PATH)/configs/audio/sku_sun_qssi/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun_qssi/audio_policy_configuration.xml

# Bluetooth
PRODUCT_PACKAGES += \
    aidl_audio_set_scenarios_bfbs \
    hfp_codec_capabilities_xml

# Media
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/media/media_sun/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/media_sun/video_system_specs.json \
    $(DEVICE_PATH)/configs/media/media_tuna_v0/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/media_tuna_v0/video_system_specs.json \
    $(DEVICE_PATH)/configs/misc/dolby_vision.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/dolby_vision.cfg

# Audio effects
# The stock effects configuration without the Dolby spatializer, which crashes the audio HAL.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/sku_sun/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/audio_effects_config.xml

# Telephony
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/permissions/moto-telephony-libs.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/moto-telephony-libs.xml

PRODUCT_PACKAGES += \
    ims_ext_common.xml \
    qti_telephony_hidl_wrapper.xml \
    qti_telephony_hidl_wrapper_prd.xml \
    qti_telephony_utils.xml \
    qti_telephony_utils_prd.xml

# Audio effects
PRODUCT_PACKAGES += \
    libbundleaidl \
    libdownmixaidl \
    libdynamicsprocessingaidl \
    libloudnessenhanceraidl \
    libreverbaidl \
    libvisualizeraidl

# WiFi
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.rtt.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.rtt.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml

# Inherit from the proprietary version
$(call inherit-product, vendor/motorola/leap/leap-vendor.mk)

# Mount points
PRODUCT_PACKAGES += \
    vendor_firmware_mnt_mountpoint \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_fsg_mountpoint_leap \
    vendor_super_modem_mountpoint_leap \
    vendor_super_fsg_mountpoint_leap

# Vendor variants of the interface libraries the stock blobs link
PRODUCT_PACKAGES += \
    android.frameworks.cameraservice.common-V1-ndk.vendor \
    android.frameworks.cameraservice.device-V2-ndk.vendor \
    android.frameworks.cameraservice.service-V2-ndk.vendor \
    android.frameworks.location.altitude-V2-ndk.vendor \
    android.frameworks.sensorservice-V1-ndk.vendor \
    android.hardware.audio.common-V3-ndk.vendor \
    android.hardware.audio.common@5.0.vendor \
    android.hardware.audio.common@7.0-enums.vendor \
    android.hardware.audio.common@7.0-util.vendor \
    android.hardware.audio.common@7.0.vendor \
    android.hardware.audio.core-V2-ndk.vendor \
    android.hardware.audio.core.sounddose-V1-ndk.vendor \
    android.hardware.audio.core.sounddose-V2-ndk.vendor \
    android.hardware.audio.effect-V2-ndk.vendor \
    android.hardware.audio.effect@7.0-util.vendor \
    android.hardware.audio.effect@7.0.vendor \
    android.hardware.audio@7.0-util.vendor \
    android.hardware.audio@7.0.vendor \
    android.hardware.automotive.vehicle@2.0.vendor \
    android.hardware.biometrics.common-V3-ndk.vendor \
    android.hardware.biometrics.common-V4-ndk.vendor \
    android.hardware.biometrics.fingerprint-V3-ndk.vendor \
    android.hardware.biometrics.face-V4-ndk.vendor \
    android.hardware.bluetooth-V1-ndk.vendor \
    android.hardware.bluetooth.audio-V3-ndk.vendor \
    android.hardware.bluetooth.audio-V4-ndk.vendor \
    android.hardware.bluetooth.audio@2.0.vendor \
    android.hardware.bluetooth.audio@2.1.vendor \
    android.hardware.bluetooth.finder-V1-ndk.vendor \
    android.hardware.bluetooth.lmp_event-V1-ndk.vendor \
    android.hardware.bluetooth@1.0.vendor \
    android.hardware.boot@1.1.vendor \
    android.hardware.camera.common-V1-ndk.vendor \
    android.hardware.camera.device-V2-ndk.vendor \
    android.hardware.camera.metadata-V2-ndk.vendor \
    android.hardware.camera.provider-V2-ndk.vendor \
    android.hardware.common-V2-ndk.vendor \
    android.hardware.common.fmq-V1-ndk.vendor \
    android.hardware.contexthub-V3-ndk.vendor \
    android.hardware.gatekeeper-V1-ndk.vendor \
    android.hardware.gnss-V4-ndk.vendor \
    android.hardware.graphics.allocator-V1-ndk.vendor \
    android.hardware.graphics.allocator-V2-ndk.vendor \
    android.hardware.graphics.allocator@2.0.vendor \
    android.hardware.graphics.allocator@3.0.vendor \
    android.hardware.graphics.allocator@4.0.vendor \
    android.hardware.graphics.bufferqueue@1.0.vendor \
    android.hardware.graphics.bufferqueue@2.0.vendor \
    android.hardware.graphics.common-V5-ndk.vendor \
    android.hardware.graphics.common@1.0.vendor \
    android.hardware.graphics.common@1.1.vendor \
    android.hardware.graphics.common@1.2.vendor \
    android.hardware.graphics.composer3-V3-ndk.vendor \
    android.hardware.graphics.composer@2.1.vendor \
    android.hardware.graphics.composer@2.2.vendor \
    android.hardware.graphics.composer@2.3.vendor \
    android.hardware.graphics.composer@2.4.vendor \
    android.hardware.graphics.mapper@2.0.vendor \
    android.hardware.graphics.mapper@2.1.vendor \
    android.hardware.graphics.mapper@3.0.vendor \
    android.hardware.graphics.mapper@4.0.vendor \
    android.hardware.health-V1-ndk.vendor \
    android.hardware.health-V3-ndk.vendor \
    android.hardware.health@1.0.vendor \
    android.hardware.health@2.0.vendor \
    android.hardware.health@2.1.vendor \
    android.hardware.identity-V5-ndk.vendor \
    android.hardware.keymaster-V4-ndk.vendor \
    android.hardware.keymaster@4.0.vendor \
    android.hardware.keymaster@4.1.vendor \
    android.hardware.light-V2-ndk.vendor \
    android.hardware.media.bufferpool2-V2-ndk.vendor \
    android.hardware.media.bufferpool@2.0.vendor \
    android.hardware.media.c2-V1-ndk.vendor \
    android.hardware.media.c2@1.0.vendor \
    android.hardware.media.c2@1.1.vendor \
    android.hardware.media.c2@1.2.vendor \
    android.hardware.media@1.0.vendor \
    android.hardware.memtrack-V1-ndk.vendor \
    android.hardware.nfc-V1-ndk.vendor \
    android.hardware.nfc@1.2.vendor \
    android.hardware.power-V5-ndk.vendor \
    android.hardware.power@1.2.vendor \
    android.hardware.radio-V2-ndk.vendor \
    android.hardware.radio-V3-ndk.vendor \
    android.hardware.radio.config-V3-ndk.vendor \
    android.hardware.radio.data-V2-ndk.vendor \
    android.hardware.radio.data-V3-ndk.vendor \
    android.hardware.radio.messaging-V3-ndk.vendor \
    android.hardware.radio.modem-V3-ndk.vendor \
    android.hardware.radio.network-V2-ndk.vendor \
    android.hardware.radio.network-V3-ndk.vendor \
    android.hardware.radio.sap-V1-ndk.vendor \
    android.hardware.radio.sim-V3-ndk.vendor \
    android.hardware.radio.voice-V3-ndk.vendor \
    android.hardware.radio@1.0.vendor \
    android.hardware.radio@1.1.vendor \
    android.hardware.radio@1.2.vendor \
    android.hardware.radio@1.3.vendor \
    android.hardware.radio@1.4.vendor \
    android.hardware.radio@1.5.vendor \
    android.hardware.radio@1.6.vendor \
    android.hardware.renderscript@1.0.vendor \
    android.hardware.secure_element-V1-ndk.vendor \
    android.hardware.secure_element@1.0.vendor \
    android.hardware.security.keymint-V2-ndk.vendor \
    android.hardware.security.keymint-V3-ndk.vendor \
    android.hardware.security.rkp-V3-ndk.vendor \
    android.hardware.security.secureclock-V1-ndk.vendor \
    android.hardware.security.sharedsecret-V1-ndk.vendor \
    android.hardware.sensors-V2-ndk.vendor \
    android.hardware.sensors@1.0.vendor \
    android.hardware.sensors@2.0-ScopedWakelock.vendor \
    android.hardware.sensors@2.0.vendor \
    android.hardware.sensors@2.1.vendor \
    android.hardware.soundtrigger3-V1-ndk.vendor \
    android.hardware.soundtrigger@2.0-core.vendor \
    android.hardware.soundtrigger@2.0.vendor \
    android.hardware.soundtrigger@2.1.vendor \
    android.hardware.soundtrigger@2.2.vendor \
    android.hardware.soundtrigger@2.3.vendor \
    android.hardware.tetheroffload-V1-ndk.vendor \
    android.hardware.thermal-V1-ndk.vendor \
    android.hardware.thermal-V2-ndk.vendor \
    android.hardware.thermal@1.0.vendor \
    android.hardware.usb-V1-ndk.vendor \
    android.hardware.uwb-V1-ndk.vendor \
    android.hardware.vibrator-V2-ndk.vendor \
    android.hardware.weaver-V2-ndk.vendor \
    android.hardware.wifi.hostapd-V2-ndk.vendor \
    android.hardware.wifi.supplicant-V3-ndk.vendor \
    android.hidl.allocator@1.0.vendor \
    android.hidl.memory.token@1.0.vendor \
    android.hidl.memory@1.0.vendor \
    android.hidl.safe_union@1.0.vendor \
    android.hidl.token@1.0-utils.vendor \
    android.media.audio.common.types-V2-ndk.vendor \
    android.media.audio.common.types-V3-ndk.vendor \
    android.system.keystore2-V1-ndk.vendor \
    android.system.net.netd-V1-ndk.vendor \
    android.system.suspend-V1-ndk.vendor \
    android.system.wifi.keystore@1.0.vendor \
    com.dsi.ant@1.0.vendor \
    libcodec2_hidl@1.0.vendor \
    libcodec2_hidl@1.1.vendor \
    libcodec2_hidl@1.2.vendor \
    libstagefright_bufferpool@2.0.1.vendor \
    vendor.nxp.nxpese@1.0.vendor

PRODUCT_PACKAGES += \
    libvndfwk_detect_jni.qti.vendor \
    qti-audio-types-aidl-V1-ndk.vendor \
    vendor.display.config@1.0.vendor \
    vendor.display.config@1.1.vendor \
    vendor.display.config@1.10.vendor \
    vendor.display.config@1.11.vendor \
    vendor.display.config@1.2.vendor \
    vendor.display.config@1.3.vendor \
    vendor.display.config@1.4.vendor \
    vendor.display.config@1.5.vendor \
    vendor.display.config@1.6.vendor \
    vendor.display.config@1.7.vendor \
    vendor.display.config@1.8.vendor \
    vendor.display.config@1.9.vendor \
    vendor.display.config@2.0.vendor \
    vendor.nxp.nxpnfc_aidl-V1-ndk.vendor \
    vendor.qti.hardware.bluetooth.audio-V1-ndk.vendor \
    vendor.qti.hardware.bluetooth.audio-V2-ndk.vendor \
    vendor.qti.hardware.bluetooth_audio@2.0.vendor \
    vendor.qti.hardware.bluetooth_audio@2.1.vendor \
    vendor.qti.hardware.camera.aon-V1-ndk.vendor \
    vendor.qti.hardware.camera.aon-V2-ndk.vendor \
    vendor.qti.hardware.camera.offlinecamera-V1-ndk.vendor \
    vendor.qti.hardware.camera.offlinecamera-V2-ndk.vendor \
    vendor.qti.hardware.display.allocator@1.0.vendor \
    vendor.qti.hardware.display.allocator@3.0.vendor \
    vendor.qti.hardware.display.allocator@4.0.vendor \
    vendor.qti.hardware.display.composer@1.0.vendor \
    vendor.qti.hardware.display.composer@2.0.vendor \
    vendor.qti.hardware.display.mapper@1.0.vendor \
    vendor.qti.hardware.display.mapper@1.1.vendor \
    vendor.qti.hardware.display.mapper@2.0.vendor \
    vendor.qti.hardware.display.mapper@3.0.vendor \
    vendor.qti.hardware.display.mapper@4.0.vendor \
    vendor.qti.hardware.display.mapperextensions@1.0.vendor \
    vendor.qti.hardware.display.mapperextensions@1.1.vendor \
    vendor.qti.hardware.display.mapperextensions@1.2.vendor \
    vendor.qti.hardware.display.mapperextensions@1.3.vendor \
    vendor.qti.hardware.paleventnotifier-V1-ndk.vendor \
    vendor.qti.hardware.perf@2.0.vendor \
    vendor.qti.hardware.perf@2.1.vendor \
    vendor.qti.hardware.perf@2.2.vendor \
    vendor.qti.hardware.qspa-V1-ndk.vendor \
    vendor.qti.hardware.servicetracker@1.0.vendor \
    vendor.qti.hardware.servicetracker@1.1.vendor \
    vendor.qti.hardware.servicetrackeraidl-V1-ndk.vendor \
    vendor.qti.hardware.wifi.supplicant-V1-ndk.vendor

# Thermal
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti
