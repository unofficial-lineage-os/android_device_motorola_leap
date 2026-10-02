/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#pragma once

#include <aidl/vendor/lineage/livedisplay/BnSunlightEnhancement.h>

#include <mutex>

namespace aidl::vendor::lineage::livedisplay::leap {

// LiveDisplay "Outdoor mode": the panel's high brightness mode, requested through Motorola's panel HAL as on
// stock (IDisplayPanel::setMode HIGH_BRIGHT / NORMAL -> SET_PANEL_FEATURE param 0 -> hbm-on/off DCS sets).
class SunlightEnhancement : public BnSunlightEnhancement {
  public:
    ndk::ScopedAStatus getEnabled(bool* _aidl_return) override;
    ndk::ScopedAStatus setEnabled(bool enabled) override;

  private:
    std::mutex mLock;
    bool mEnabled = false;
    bool mSynced = false;
};

}  // namespace aidl::vendor::lineage::livedisplay::leap
