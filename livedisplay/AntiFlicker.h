/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#pragma once

#include <aidl/vendor/lineage/livedisplay/BnAntiFlicker.h>
#include <android/binder_auto_utils.h>

#include <mutex>

namespace aidl::vendor::lineage::livedisplay::leap {

class AntiFlicker : public BnAntiFlicker {
  public:
    ndk::ScopedAStatus getEnabled(bool* _aidl_return) override;
    ndk::ScopedAStatus setEnabled(bool enabled) override;

  private:
    std::mutex mLock;
    bool mEnabled = false;
};

}  // namespace aidl::vendor::lineage::livedisplay::leap
