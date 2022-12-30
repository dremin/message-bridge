#!/bin/sh
# Based on example from https://developer.apple.com/forums/thread/130855
# Fail if any command fails.
set -e
# Check and unpack the arguments.
if [ $# -ne 2 ]
then
    echo "usage: package-archive.sh /path/to.xcarchive identity" > /dev/stderr
    exit 1
fi
ARCHIVE="$1"
IDENTITY="$2"
PRODUCT="MessageBridge"
WORKDIR="${PRODUCT} `date '+%Y-%m-%d_%H.%M.%S'`"
ZIPROOT="${WORKDIR}/${PRODUCT}"
APP="${ZIPROOT}/bin/${PRODUCT}"

# Set up directories to be zipped
mkdir -p "${ZIPROOT}"
mkdir -p "${ZIPROOT}/bin"

# Copy files into the directories for zipping
cp -R "${ARCHIVE}/Products/usr/local/bin/${PRODUCT}" "${ZIPROOT}/bin/"
cp "${PRODUCT}.command" "${ZIPROOT}/"
cp -R "Public/" "${ZIPROOT}/Public"

# Remove macOS junk
rm "${ZIPROOT}/Public/.DS_Store"

# Remove any existing signature from the app
codesign --remove-signature "${APP}"

# Sign the app
# To find the identity name to use run: security find-identity -p basic -v
# Example: "Developer ID Application: Test McTesterson (42069)"
codesign -s "${IDENTITY}" -f --timestamp -i me.scj.MessageBridge -o runtime --entitlements "app.entitlements" "${APP}"

# zip up the app
cd "${ZIPROOT}" && zip -r "${PRODUCT}.zip" *

# Notarize the zip
xcrun notarytool submit "${PRODUCT}.zip" --keychain-profile "Sam" --wait
