#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=whyred
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

MK_ROOT="$MY_DIR"/../../..

HELPER="$MK_ROOT"/vendor/mk/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$MK_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"
extract "$MY_DIR"/proprietary-files-twrp.txt "$SRC" "$SECTION"

TWRP_QSEECOMD="$MK_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary/recovery/root/sbin/qseecomd
TWRP_GATEKEEPER="$MK_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary/recovery/root/sbin/android.hardware.gatekeeper@1.0-service
TWRP_KEYMASTER="$MK_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary/recovery/root/sbin/android.hardware.keymaster@3.0-service
GOODIX="$MK_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary/vendor/lib64/libgf_ca.so

sed -i "s|/system/bin/linker64|/sbin/linker64\x0\x0\x0\x0\x0\x0|g" "$TWRP_QSEECOMD"
sed -i "s|/system/bin/linker64|/sbin/linker64\x0\x0\x0\x0\x0\x0|g" "$TWRP_GATEKEEPER"
sed -i "s|/system/bin/linker64|/sbin/linker64\x0\x0\x0\x0\x0\x0|g" "$TWRP_KEYMASTER"
sed -i "s|/system/etc/firmware|/vendor/firmware\x0\x0\x0\x0|g" $GOODIX

BLOB_ROOT="$MK_ROOT"/vendor/"$VENDOR"/"$DEVICE"/proprietary
patchelf --set-soname libicuuc-v27.so $BLOB_ROOT/vendor/lib/libicuuc-v27.so
patchelf --set-soname libminikin-v27.so $BLOB_ROOT/vendor/lib/libminikin-v27.so

patchelf --replace-needed android.frameworks.sensorservice@1.0.so android.frameworks.sensorservice@1.0-v27.so $BLOB_ROOT/vendor/lib/libvidhance_gyro.so
patchelf --replace-needed libminikin.so libminikin-v27.so $BLOB_ROOT/vendor/lib/libMiWatermark.so
patchelf --replace-needed libicuuc.so libicuuc-v27.so $BLOB_ROOT/vendor/lib/libMiWatermark.so

patchelf --remove-needed vendor.xiaomi.hardware.mtdservice@1.0.so "$BLOB_ROOT"/vendor/bin/mlipayd
patchelf --remove-needed vendor.xiaomi.hardware.mtdservice@1.0.so "$BLOB_ROOT"/vendor/lib64/libmlipay.so

"$MY_DIR"/setup-makefiles.sh
