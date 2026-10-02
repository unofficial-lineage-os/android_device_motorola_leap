/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#pragma once

#include <android/binder_ibinder.h>

namespace aidl::vendor::lineage::livedisplay::leap {

// Motorola's panel HAL (vendor/bin/hw/com.motorola.hardware.display.panel-service, AIDL V2). Transaction codes
// recovered from the stock com.motorola.hardware.display.panel-V2-ndk.so proxies: BpDisplayPanel::setDcMode = 4,
// BpDisplayPanel::setMode = 5. Both take one int32 and return an int32 (0 = success).
constexpr transaction_code_t kTxnSetDcMode = 4;
constexpr transaction_code_t kTxnSetMode = 5;

// Calls IDisplayPanel method |code| with |value|; true if the HAL returned 0. |what| names it in the log.
bool MotoPanelCall(transaction_code_t code, int32_t value, const char* what);

}  // namespace aidl::vendor::lineage::livedisplay::leap
