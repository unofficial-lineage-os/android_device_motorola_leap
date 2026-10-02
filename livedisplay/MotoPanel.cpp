/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "vendor.lineage.livedisplay-service-leap"

#include "MotoPanel.h"

#include <android-base/logging.h>
#include <android/binder_auto_utils.h>
#include <android/binder_manager.h>
#include <android/binder_parcel.h>

namespace aidl::vendor::lineage::livedisplay::leap {

namespace {

constexpr const char* kPanelInstance = "com.motorola.hardware.display.panel.IDisplayPanel/default";

// AIBinder_prepareTransaction needs a class associated with the proxy (it writes the class
// descriptor as the interface token); without one it returns STATUS_INVALID_OPERATION (-38).
void* onCreate(void*) { return nullptr; }
void onDestroy(void*) {}
binder_status_t onTransact(AIBinder*, transaction_code_t, const AParcel*, AParcel*) {
    return STATUS_UNKNOWN_TRANSACTION;
}
AIBinder_Class* panelClass() {
    static AIBinder_Class* clazz = AIBinder_Class_define(
            "com.motorola.hardware.display.panel.IDisplayPanel", onCreate, onDestroy, onTransact);
    return clazz;
}

}  // namespace

bool MotoPanelCall(transaction_code_t code, int32_t value, const char* what) {
    ndk::SpAIBinder panel(AServiceManager_waitForService(kPanelInstance));
    if (panel.get() == nullptr) {
        LOG(ERROR) << "Motorola panel HAL " << kPanelInstance << " not available";
        return false;
    }
    if (!AIBinder_associateClass(panel.get(), panelClass())) {
        LOG(ERROR) << "panel HAL does not speak IDisplayPanel";
        return false;
    }

    AParcel* in = nullptr;
    AParcel* out = nullptr;
    binder_status_t status = AIBinder_prepareTransaction(panel.get(), &in);
    if (status != STATUS_OK) {
        LOG(ERROR) << "prepareTransaction failed: " << status;
        return false;
    }
    status = AParcel_writeInt32(in, value);
    if (status != STATUS_OK) {
        LOG(ERROR) << "writeInt32 failed: " << status;
        AParcel_delete(in);
        return false;
    }
    status = AIBinder_transact(panel.get(), code, &in, &out, 0);
    if (status != STATUS_OK) {
        LOG(ERROR) << what << " transact failed: " << status;
        AParcel_delete(out);
        return false;
    }

    ndk::ScopedAStatus ret;
    AStatus* raw = nullptr;
    status = AParcel_readStatusHeader(out, &raw);
    if (status == STATUS_OK) ret.set(raw);
    int32_t result = -1;
    if (status == STATUS_OK && ret.isOk()) status = AParcel_readInt32(out, &result);
    AParcel_delete(out);

    if (status != STATUS_OK || !ret.isOk()) {
        LOG(ERROR) << what << "(" << value << ") rejected: " << ret.getDescription();
        return false;
    }
    LOG(INFO) << what << "(" << value << ") -> " << result;
    return result == 0;
}

}  // namespace aidl::vendor::lineage::livedisplay::leap
