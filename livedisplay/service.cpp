/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "vendor.lineage.livedisplay-service-leap"

#include <android-base/logging.h>
#include <android/binder_manager.h>
#include <android/binder_process.h>

#include "AntiFlicker.h"
#include "SunlightEnhancement.h"

using ::aidl::vendor::lineage::livedisplay::leap::AntiFlicker;
using ::aidl::vendor::lineage::livedisplay::leap::SunlightEnhancement;

int main() {
    ABinderProcess_setThreadPoolMaxThreadCount(0);

    LOG(INFO) << "leap LiveDisplay HAL service (anti-flicker, sunlight enhancement via Motorola panel HAL) starting.";

    auto af = ndk::SharedRefBase::make<AntiFlicker>();
    std::string instance = std::string() + AntiFlicker::descriptor + "/default";
    binder_status_t status = AServiceManager_addService(af->asBinder().get(), instance.c_str());
    CHECK_EQ(status, STATUS_OK);

    auto se = ndk::SharedRefBase::make<SunlightEnhancement>();
    instance = std::string() + SunlightEnhancement::descriptor + "/default";
    status = AServiceManager_addService(se->asBinder().get(), instance.c_str());
    CHECK_EQ(status, STATUS_OK);

    ABinderProcess_joinThreadPool();
    return EXIT_FAILURE;  // should not reach
}
