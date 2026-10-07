#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# device.mk for leap — SKELETON DRAFT (provenance markers as in BoardConfig.mk)
#

DEVICE_PATH := device/motorola/leap

# Qualcomm common                                                          [D]
$(call inherit-product, hardware/qcom-caf/common/common.mk)

# Virtual A/B with vendor ramdisk                                          [H][D]
# Virtual A/B WITH compression. MUST be compression_with_xor.mk, not launch_with_vendor_ramdisk.mk
# (findings.md D10). vendor.prop was seeded from stock, which declares
#   ro.virtual_ab.compression.enabled / .userspace.snapshots.enabled / .compression.xor.enabled
# but launch_with_vendor_ramdisk.mk ships NO snapuserd. Userspace snapshots without the snapuserd
# daemon in the vendor ramdisk = first-stage init cannot map the six dm-user snapshot devices =
# hard bootloop on the first boot after a sideload (observed on device 2026-09-19; the sideload
# itself succeeds because writing a COW uses CowWriter directly and never needs the daemon).
# compression_with_xor.mk -> compression.mk -> launch_with_vendor_ramdisk.mk, and adds
# PRODUCT_VIRTUAL_AB_COMPRESSION := true plus snapuserd{,.vendor_ramdisk,.recovery}.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression_with_xor.mk)

# Optional snapuserd tuning knob: commented out in AOSP's compression.mk:29, but stock leap sets
# it, so carry it explicitly rather than leaving it in vendor.prop where it would collide.
PRODUCT_VENDOR_PROPERTIES += ro.virtual_ab.compression.threads=true

# Dynamic partitions (single `super`, Virtual A/B) — required for image sizing   [D common.mk:350]
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# VINTF — the framework must tolerate every HAL our vendor manifests declare.        [D][M]
# qcom-caf covers the qti/qcom set, hardware/motorola the shared Moto set, and
# device/motorola/leap/vintf the 15 leap-specific ones (fdr, lpsensing, sxf, powershare,
# wlc, MotoHealth, ifaa, panel/touch, arcsoft postproc, dolby dms/dvs, zuialarm).
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    device/motorola/leap/vintf/device_framework_matrix.xml \
    hardware/motorola/vintf/device_framework_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml

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
# NOTE: dodge also runs odm postinstall `xbl_config_arb_check` — investigate the Moto
# equivalent before enabling anything ARB-related. Left OUT deliberately.

# API levels                                                               TODO(build.prop)
# Shipped on Android 15 → shipping API 35 even after the A16 update.
PRODUCT_SHIPPING_API_LEVEL := 35

# Boot animation
TARGET_SCREEN_HEIGHT := 2992
TARGET_SCREEN_WIDTH := 1224
# TODO(spec/panel dts): confirm inner-panel resolution for bootanim sizing.

# Fold configuration                                                       [M — zeekr fold/]
# device_state_configuration.xml + display_layout_configuration.xml + display_id_*.xml.
# Structure copied from zeekr; leap display IDs must come from `dumpsys display` on device.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/fold/device_state_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/devicestate/device_state_configuration.xml \
    $(DEVICE_PATH)/fold/display_layout_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_layout_configuration.xml \
    $(DEVICE_PATH)/fold/display_id_4630947043778501779.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947043778501779.xml \
    $(DEVICE_PATH)/fold/display_id_4630947043778501780.xml:$(TARGET_COPY_OUT_VENDOR)/etc/displayconfig/display_id_4630947043778501780.xml

# D20: framework-res vendor RRO (fold states, 120 Hz peak, brightness, stock misc) — see rro_overlays/.
PRODUCT_PACKAGES += \
    LeapFrameworksResOverlay \
    LeapSystemUIOverlay \
    LeapApertureOverlay

# D34: NFC tag reader app (zeekr)
PRODUCT_PACKAGES += \
    Tag

# D23: hinge angle feature (stock exposes android.sensor.hinge_angle)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.hinge_angle.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.hinge_angle.xml

# D36: DC dimming = LiveDisplay IAntiFlicker bridged to Motorola's IDisplayPanel::setDcMode
# (leap has no writable DC sysfs node; stock sets DC through /dev/dri/card0). See livedisplay/.
PRODUCT_PACKAGES += \
    vendor.lineage.livedisplay-service.leap

# D24: stock vndservicemanager under bin/hw + our rc (source module dropped; see proprietary-files.txt)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init/vndservicemanager.leap.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/vndservicemanager.leap.rc \
    $(DEVICE_PATH)/init/init.leap.touch-gesture.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.leap.touch-gesture.rc

# D26: boot animation on BOTH panels (arcfox 19087ef). Without it the cover panel keeps the bootloader
# splash until the first fold: DisplayManager/SurfaceFlinger/SDM all believe it is already OFF, so the
# framework's STATE_OFF after boot is swallowed and no DRM commit ever reaches DSI-2. Drawing on it
# powers it ON for real, so the later OFF is a real transition. Stock does the same with its own
# `bootanim-cli`; AOSP's multidisplay aconfig flag is the equivalent (is_fixed_read_only, so build-time).
$(call soong_config_set_bool,bootanimation,multidisplay,true)

# D20: wlan firmware config symlinks (see Android.bp)
PRODUCT_PACKAGES += \
    leap_wlan_symlink_qcom_cfg \
    leap_wlan_symlink_prc_cfg \
    leap_wlan_symlink_mac
# D20: display_layout_configuration.xml + display_id_<id>.xml added (IDs from SurfaceFlinger, first boot).

# Fold-state sensor wiring: hall_phone_case_detect (tlmm 54) per
# kernel-devicetree qcom/sun-leap-pvt-sensor-overlay.dtsi:93 — the HAL-side consumer
# is ORIGINAL WORK (hardware/motorola has no fold/hinge/posture support).

# Motorola glue                                                            [H]
# TODO(hardware/motorola): pull the sensors SubHAL / aidl touch modules — read their
# Android.bp for the real module names before adding PRODUCT_PACKAGES entries here.

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(DEVICE_PATH)/overlay \
    $(DEVICE_PATH)/overlay-lineage \
    $(DEVICE_PATH)/overlay-static
# D30: overlay-static holds overlays that must be compiled INTO the app (Launcher3's device_profiles /
# default_workspace use its private attrs and strings, which an auto-generated RRO cannot resolve).
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS += $(DEVICE_PATH)/overlay-static
PRODUCT_ENFORCE_RRO_TARGETS := *

# Ramdisk / rootdir                                                        TODO(firmware)
# init.mmi.*.rc, init.leap.rc, ueventd — transcribe from stock vendor ramdisk after
# unpacking vendor_boot (sm8475-common/init shows the Moto shape).

# Fingerprints — VERIFIED from the A15 package (system info.txt + vendor build.prop).
# System:  motorola/leap_g/leap:15/V2VL35.42-148-2-5-1/2203fb-37b70:user/release-keys
# Vendor:  motorola/leap/leap:15/VVL35V.42-148-2-ST3.18/2203fb:user/release-keys
# Blobs must match the vendor fingerprint; SafetyNet/DDK spoof uses the system one.
# When rebasing to A16 blobs (W1VL36H.59-55-5), re-pin both. Left commented until the A16 pin:
# PRODUCT_BUILD_PROP_OVERRIDES += \
#     BuildDesc="leap_g-user 15 V2VL35.42-148-2-5-1 2203fb-37b70 release-keys" \
#     BuildFingerprint=motorola/leap_g/leap:15/V2VL35.42-148-2-5-1/2203fb-37b70:user/release-keys

# ============================================================================================
# BOOT-CRITICAL HALs (findings.md D14)
# ============================================================================================
# Found by diffing dodge's PRODUCT_PACKAGES (149) against ours (35): we were missing 130, and
# the missing set included everything needed to reach a boot animation. Symptom was a device
# that completed first-stage mount, ground for ~4.5 minutes in second-stage init, never lit the
# display, never enumerated USB, then reset to the bootloader.
#
#   vndservicemanager            - the vendor servicemanager HIDL vendor services register with.
#   display.composer-service     - THE display HAL (HWC) SurfaceFlinger talks to. We shipped the
#                                  allocator/color/demura/panel/touch services but not the
#                                  composer, so there was no display output path at all.
#                                  Resolves to hardware/qcom-caf/sm8750/display/hal/composer via
#                                  our PRODUCT_SOONG_NAMESPACES.
#   usb-service.qti              - the USB HAL (stock blob serves BOTH IUsb and IUsbGadget/default;
#                                  the separate source usb.gadget-service.qti was REMOVED (D15s) —
#                                  it registered the same IUsbGadget/default instance). Without it the gadget never comes up, which is
#                                  why no adb/MTP interface ever appeared on a normal boot.
#   health-service.qti           - init blocks on the health HAL early in second stage.
#   power / thermal / memtrack   - core QTI HALs dodge treats as mandatory.
#   sensors-service.multihal     - sensors HAL.
# All 12 verified to exist as buildable modules in this tree before being listed here.
# [D refs/sm8750-common/common.mk — dodge ships every one of these]
PRODUCT_PACKAGES += \
# ============================================================================================
# D15: SOURCE modules that exist in the tree but were never listed (findings.md D15).
# Found by screening the stock->ours vendor diff against module-info.json: 117 of the 455
# missing stock files are produced by source modules, not blobs. Leaf modules must be listed;
# interface/utility libs come in automatically as DT_NEEDED deps of the blobs.
# Every name below was verified to exist in module-info.json before being listed.
# ============================================================================================
# audio HAL (source: hardware/qcom-caf/sm8750/audio) — core, effects, BT/USB/submix, soundfx
# display boot script + qspa rc (source)
PRODUCT_PACKAGES += \
    init.qti.display_boot.rc \
    qspa_vendor.rc

# data / wifi (source)
PRODUCT_PACKAGES += \
    IPACM_cfg.xml \
    IPACM_Filter_cfg.xml \
# DRM clearkey (source)
PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey.xml

# feature permission XMLs (source)
PRODUCT_PACKAGES += \
    android.hardware.hardware_keystore.xml \
    features_com.android.virt.xml

# QTI framework-detect libs (source, system_ext)
# D15e: older AIDL interface versions that DISABLE_DEPS blobs dlopen at runtime. Soong will not
# auto-install them (no declared dep), so force the vendor variants in, dodge-style.
# D15h: the SOURCE QTI audio HAL (hardware/qcom-caf/sm8750/audio, an A15-era snapshot) does not
# compile against Android 16 audio AIDL (StreamCommonDelegator abstract; PAL converters, offload
# effects all fail). Stock's PREBUILT audio HAL libs are used instead (proprietary-files.txt,
# renamed modules + DISABLE_DEPS). They link the A15 AIDL versions, installed here:
# Boot control HAL — REQUIRED for A/B slot switching. Without it update_engine_sideload dies at
# startup: "AIDL IBootControl not available" / "Error getting bootctrl v1.0 module" /
# "Error initializing the BootControlInterface" (observed on device 2026-09-19).
#
# MUST be QTI's, not AOSP's generic one. See findings.md D8. Motorola's bootloader is
# QTI-derived and reads the slot's **GPT partition attribute bits** (priority / tries-remaining /
# successful / unbootable). AOSP's libboot_control instead keeps a `bootloader_control` struct in
# the **misc** partition. With the generic HAL a sideload completes, update_engine calls
# SetActiveBootSlot(a), the write lands in misc, the bootloader never reads it, and the device
# quietly boots the old slot again — exactly what happened on 2026-09-19:
#   current-slot: b / slot-unbootable:a: yes / slot-retry-count:a: 6 (never even attempted).
# [D refs/sm8750-common/common.mk:123-124 (dodge, same SoC), refs/sm8475-common/sm8475.mk:84-85]
#
# The build blocker that previously forced the generic HAL is solved in BoardConfig.mk via
# TARGET_PREBUILT_KERNEL_HEADERS (findings.md D9).
#
# com.android.hardware.boot (the APEX carrying AOSP's default impl) is deliberately NOT listed:
# two providers of IBootControl/default would race.
# D19: the vendor-side boot HAL was retired in D17-b and its stock blob cannot be imported
# ("found in multiple namespaces": hardware/qcom-caf/bootctrl is a dedicated namespace) — so it is
# SOURCE, exactly as dodge ships it. Without it there was no IBootControl/default at all.
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti \
    android.hardware.boot-service.qti.recovery

# Fastboot HAL — without it fastbootd answers FAILED (remote: 'Unknown variable') to EVERY
# getvar, `version` included, so it cannot flash logical partitions and is useless as a fallback
# path (observed 2026-09-19, findings.md D8a). [D refs/sm8750-common/common.mk:177]
PRODUCT_PACKAGES += \
    android.hardware.fastboot-service.example_recovery \
    fastbootd

# Update engine — REQUIRED for A/B. Without update_engine_sideload the recovery sideload
# dies with "Can't run /system/bin/update_engine_sideload (No such file or directory)"
# (observed on device 2026-09-19), and without update_engine the running system can't take OTAs.
# AB_OTA_UPDATER:=true alone does NOT pull these in. [D sm8750-common/common.mk:462]
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Soong namespace — device/motorola/leap/Android.bp declares soong_namespace{}, so nothing
# inside this tree is reachable from PRODUCT_PACKAGES unless the namespace is listed here.
# (dodge does the same: sm8750-common/common.mk:407 `PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)`)
PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)

# Init / fstab                                                              [D sm8750-common]
# fstab.default MUST be a module: first-stage mount reads it from vendor_ramdisk, and the
# running system needs the /vendor/etc copy. Previously it was only referenced by
# TARGET_RECOVERY_FSTAB, so nothing installed it.
# init.qcom.recovery.rc brings up USB/adb in recovery AND creates /dev/block/bootdevice
# (verified on device 2026-09-19: without it recovery reports
#  "failed to stat /dev/block/bootdevice/by-name/misc" and presents no USB interface).
PRODUCT_PACKAGES += \
    fstab.default \
    fstab.default.vendor_ramdisk \
    init.qcom.recovery.rc

# Vendor hardware init scripts — see findings.md D13. vendor/etc/init/hw/ was EMPTY:
# init.rc imports /vendor/etc/init/hw/init.${ro.hardware}.rc and none of these were ever
# installed (proprietary-files.txt has 122 vendor/etc/init/ entries but none under init/hw/).
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


# WiFi                                                                      [D common.mk:523]
# None of these are blobs (verified against proprietary-files.txt) — stock relies on the
# source-built qcom wifi stack, so this is a real gap, not a duplicate. hal_proxy_daemon
# (a blob) links libwifi-hal-qcom, which is why check_elf_file caught the omission.
# BOARD_WLAN_CHIP left unset like dodge → hardware/qcom/wlan conditions_default (legacy).
# libwifi-hal-qcom is NOT listed here: the source name is only a cc_defaults, and the real
# libwifi-hal-qcom.so is a stock blob (restored to proprietary-files.txt) that hal_proxy_daemon needs.
# D19: the source wifi stack was retired in D17-b on the theory stock ships blobs — it does not
# (no wifi-service/wpa_supplicant/hostapd blobs exist); the image had NO wifi HAL at all. Restored
# dodge's exact block. The stock libwifi-hal-qcom.so blob is shipped as libwifi-hal-qcom-vendor.so
# for hal_proxy_daemon, so the source libwifi-hal-qcom no longer collides with it.
PRODUCT_PACKAGES += \
    android.hardware.wifi-service \
    hostapd \
    libwifi-hal-ctrl \
    libwifi-hal-qcom \
    wpa_supplicant \
    wpa_supplicant.conf

# D19: sensors multihal + clearkey DRM — root-namespace AOSP HALs stock also builds from source
# (hardware/interfaces); their blobs cannot be imported same-named (D17-e rule b), and D17-b had
# retired the source packages without replacing them. Sub-HALs (sensors.qsh/moto) stay blobs.
PRODUCT_PACKAGES += \
    android.hardware.sensors-service.multihal \
    android.hardware.drm-service.clearkey

# D19: ipacm (tethering offload HAL, IOffload/default) — blob collides with the exported
# hardware/qcom-caf/sm8750/data-ipa-cfg-mgr namespace, so SOURCE as dodge does. Not boot-critical.
PRODUCT_PACKAGES += \
    ipacm

# D19-d: vibrator HAL from SOURCE (vendor/qcom/opensource/vibrator, same QTI OL/CL/Selector code stock
# ships). The stock blob set (service + impl + OL/CL/Sel + libqtivibratoreffect) dies in linker64
# soinfo::relocate on every start after patchelf rewriting; with IVibrator/default declared in VINTF,
# VibratorManagerService blocks in nativeGetVibratorIds and the Watchdog kills system_server at 66 s
# (tools/logs_d18_0122) — the vibrator crash became THE boot blocker once health was fixed.
# HapticsPolicy.xml / Hapticsconfig.xml / excluded-input-devices.xml stay STOCK (in the PF).
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service

# D19-f: stock audio configs whose basenames collide with source module names (so the PF cannot
# carry them). Without sku_sun/audio_policy_configuration.xml the QTI audio HAL falls back to a
# generic port list with an audio/mpeg offload port; audioserver opens it at boot, the open fails
# (AHAL_AlsaUtils: invalid format) and the HAL aborts ("Pure virtual function called") every 5 s,
# so AudioService never comes up (tools/logs_d19_0230). Copied verbatim from the stock dump.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/sku_sun/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/audio_policy_configuration.xml \
    $(DEVICE_PATH)/configs/audio/sku_sun/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/audio_effects.xml \
    $(DEVICE_PATH)/configs/audio/sku_sun/vendor_audio_interfaces.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/vendor_audio_interfaces.xml \
    $(DEVICE_PATH)/configs/audio/sku_sun_qssi/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun_qssi/audio_policy_configuration.xml

# D19-f (cont.): the remaining stock vendor/etc files the PF cannot carry for the same reason
# (basename == a source module: Bluetooth's hfp/le_audio configs, media video_system_specs.json,
# dolby_vision.cfg). Full inventory: findings.md D19-f. WFD/StrongBox/charger-res left out on purpose.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/media/media_sun/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/media_sun/video_system_specs.json \
    $(DEVICE_PATH)/configs/media/media_tuna_v0/video_system_specs.json:$(TARGET_COPY_OUT_VENDOR)/etc/media_tuna_v0/video_system_specs.json \
    $(DEVICE_PATH)/configs/misc/dolby_vision.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/dolby_vision.cfg

PRODUCT_PACKAGES += \
    aidl_audio_set_scenarios_bfbs \
    hfp_codec_capabilities_xml

# D19-g: audio effects. (1) audio_effects_config.xml now comes from the device tree with the Dolby
# spatializer entries removed — the A15 libswspatializeraidl.so crashed the audio HAL on every
# framework query (19×/min) and put AudioService on the Watchdog (tools/logs_d19_0628). (2) The
# AOSP AIDL effect libs the QTI config dlopens by name are SOURCE, as dodge ships them; their stock
# copies were `-vendor`-renamed by D17-d and therefore never found.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/audio/sku_sun/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_sun/audio_effects_config.xml

# D19-i: declare the Moto telephony/IMS extension jars (see configs/permissions/moto-telephony-libs.xml)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/permissions/moto-telephony-libs.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/moto-telephony-libs.xml

PRODUCT_PACKAGES += \
    ims_ext_common.xml \
    qti_telephony_hidl_wrapper.xml \
    qti_telephony_hidl_wrapper_prd.xml \
    qti_telephony_utils.xml \
    qti_telephony_utils_prd.xml

PRODUCT_PACKAGES += \
    libbundleaidl \
    libdownmixaidl \
    libdynamicsprocessingaidl \
    libloudnessenhanceraidl \
    libreverbaidl \
    libvisualizeraidl

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.aware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.aware.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.passpoint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.passpoint.xml \
    frameworks/native/data/etc/android.hardware.wifi.rtt.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.rtt.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml

# Proprietary
$(call inherit-product, vendor/motorola/leap/leap-vendor.mk)

# D15x: vendor mount-point directories (findings.md D15x). extract-utils never imports empty dirs, so
# /vendor/{firmware_mnt,dsp,bt_firmware,fsg} did not exist and NONE of those partitions ever mounted:
# no GPU firmware (gen80000_sqe.fw -> no /dev/kgsl-3d0 -> SurfaceFlinger 'no suitable EGLConfig'),
# no IPA/TZ/CDSP/SLPI firmware. [D refs/sm8750-common/common.mk:346]
PRODUCT_PACKAGES += \
    vendor_firmware_mnt_mountpoint \
    vendor_bt_firmware_mountpoint \
    vendor_dsp_mountpoint \
    vendor_fsg_mountpoint_leap \
    vendor_super_modem_mountpoint_leap \
    vendor_super_fsg_mountpoint_leap


# D15z: the stock A15 audio HAL blob (libaudiocorehal.qti.so) links libaudioserviceexampleimpl.so (AOSP example impl lib)
# D15z: the stock composer blob links composer3-V1 (source tree builds V3 by default)
PRODUCT_PACKAGES +=

# D15z-b: remaining DT_NEEDED of the stock composer blob (were only pulled in by the removed source composer)
PRODUCT_PACKAGES +=

# D16-a: audio HAL blob needs paleventnotifier-V1
# D16-c: AOSP graphics.composer3 V3 is a frozen AOSP interface -> source lib is ABI-stable; the stock
# composer blob links it. (A blob copy collides with the root-namespace source install rule, D15m.)

# D17-e: interface libs the stock blobs link that no blob provides (source, frozen ABI; D15e pattern)
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

# D17-f: dual-variant (system_ext+vendor) source modules the blobs need — blob cannot be same-named (D15a)
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

# D17-g: thermal HAL from QTI source (same-named blob is rejected by fsgen: found in multiple namespaces)
PRODUCT_PACKAGES += \
    android.hardware.thermal-service.qti

# D17-h/D19-b: the LineageOS compat protobuf-lite 21.12 shim is system_ext_specific — vendor blobs
# cannot load it (linker: "libprotobuf-cpp-lite-21.12.so not found" for qcrilNrd, sensors.qti, …).
# Stock's own vendor copies are shipped instead as libprotobuf-cpp-{lite,full}-21.12-vendor.so.
