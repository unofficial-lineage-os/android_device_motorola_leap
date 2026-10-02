/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "vendor.lineage.livedisplay-service-leap"

#include "SunlightEnhancement.h"

#include "MotoPanel.h"

namespace aidl::vendor::lineage::livedisplay::leap {

namespace {

// IDisplayPanel::setMode(PanelMode) goes unchanged to displaypanel.default.so, whose mode table is
// NORMAL = 0 -> (HBM 0, CABC 0, ACL 0) and HIGH_BRIGHT = 3 -> (HBM 1, CABC 0, ACL 0); of the three,
// leap's panels only implement HBM.
constexpr int32_t kModeNormal = 0;
constexpr int32_t kModeHighBright = 3;

}  // namespace

ndk::ScopedAStatus SunlightEnhancement::getEnabled(bool* _aidl_return) {
    std::lock_guard<std::mutex> lock(mLock);
    *_aidl_return = mEnabled;
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus SunlightEnhancement::setEnabled(bool enabled) {
    std::lock_guard<std::mutex> lock(mLock);
    // LiveDisplay re-sends the state on every update. Forward the first call (the kernel keeps its state if
    // this service restarts) and real changes only.
    if (mSynced && enabled == mEnabled) {
        return ndk::ScopedAStatus::ok();
    }
    if (!MotoPanelCall(kTxnSetMode, enabled ? kModeHighBright : kModeNormal, "setMode")) {
        return ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }
    mEnabled = enabled;
    mSynced = true;
    return ndk::ScopedAStatus::ok();
}

}  // namespace aidl::vendor::lineage::livedisplay::leap
