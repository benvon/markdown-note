#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="${APP_NAME:-MarkdownNote}"
BUNDLE_ID="${BUNDLE_ID:-net.benvon.markdown-note}"
APP_VERSION="${APP_VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
MINIMUM_OS_VERSION="${MINIMUM_OS_VERSION:-14.0}"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"

STAGE_DIR="${ROOT_DIR}/.build/release-stage"
APP_BUNDLE_PATH="${STAGE_DIR}/${APP_NAME}.app"
DMG_STAGE_DIR="${STAGE_DIR}/dmg-root"

cd "${ROOT_DIR}"

rm -rf "${STAGE_DIR}" "${OUTPUT_DIR}"
mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS" "${APP_BUNDLE_PATH}/Contents/Resources" "${OUTPUT_DIR}"

swift build -c release --product MarkdownNoteApp
BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="${BIN_DIR}/MarkdownNoteApp"

if [[ ! -f "${BIN_PATH}" ]]; then
  echo "Expected release binary not found at ${BIN_PATH}" >&2
  exit 1
fi

cp "${BIN_PATH}" "${APP_BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"

cat > "${APP_BUNDLE_PATH}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${BUILD_NUMBER}</string>
  <key>LSMinimumSystemVersion</key>
  <string>${MINIMUM_OS_VERSION}</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp --sign "${SIGNING_IDENTITY}" "${APP_BUNDLE_PATH}"
fi

ZIP_PATH="${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.zip"
PKG_PATH="${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.pkg"
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${APP_VERSION}.dmg"

# Finder-runnable app bundle output.
cp -R "${APP_BUNDLE_PATH}" "${OUTPUT_DIR}/${APP_NAME}.app"

ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE_PATH}" "${ZIP_PATH}"

if [[ -n "${PKG_SIGNING_IDENTITY:-}" ]]; then
  pkgbuild \
    --component "${APP_BUNDLE_PATH}" \
    --install-location /Applications \
    --sign "${PKG_SIGNING_IDENTITY}" \
    "${PKG_PATH}"
else
  pkgbuild \
    --component "${APP_BUNDLE_PATH}" \
    --install-location /Applications \
    "${PKG_PATH}"
fi

# Stage DMG contents with an Applications shortcut for drag-and-drop installs.
mkdir -p "${DMG_STAGE_DIR}"
cp -R "${APP_BUNDLE_PATH}" "${DMG_STAGE_DIR}/${APP_NAME}.app"
ln -s /Applications "${DMG_STAGE_DIR}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGE_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "Release artifacts created in ${OUTPUT_DIR}:"
ls -lh "${OUTPUT_DIR}"
