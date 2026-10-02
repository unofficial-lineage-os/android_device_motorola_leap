/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "vendor.lineage.livedisplay-service-leap"

#include "AntiFlicker.h"

#include "MotoPanel.h"

namespace aidl::vendor::lineage::livedisplay::leap {

namespace {

// IDisplayPanel::setDcMode(PanelDcMode). The HAL logs "setDcMode: DC mode = ON/OFF" and
// "Success set DC to 1/0 for Primary display" for 1/0.
constexpr int32_t kDcOff = 0;
constexpr int32_t kDcOn = 1;

}  // namespace

ndk::ScopedAStatus AntiFlicker::getEnabled(bool* _aidl_return) {
    std::lock_guard<std::mutex> lock(mLock);
    *_aidl_return = mEnabled;
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus AntiFlicker::setEnabled(bool enabled) {
    std::lock_guard<std::mutex> lock(mLock);
    if (!MotoPanelCall(kTxnSetDcMode, enabled ? kDcOn : kDcOff, "setDcMode")) {
        return ndk::ScopedAStatus::fromExceptionCode(EX_ILLEGAL_STATE);
    }
    mEnabled = enabled;
    return ndk::ScopedAStatus::ok();
}

}  // namespace aidl::vendor::lineage::livedisplay::leap
