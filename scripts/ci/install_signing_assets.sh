#!/bin/bash
set -euo pipefail

if [[ -z "${BUILD_CERTIFICATE_BASE64:-}" || -z "${BUILD_PROVISION_PROFILE_BASE64:-}" ]]; then
  echo "Signing secrets are missing."
  exit 1
fi

CERT_PATH="$RUNNER_TEMP/build_certificate.p12"
PROFILE_PATH="$RUNNER_TEMP/build_profile.mobileprovision"
PROFILE_PLIST="$RUNNER_TEMP/build_profile.plist"
KEYCHAIN_PATH="$RUNNER_TEMP/build.keychain-db"

echo -n "$BUILD_CERTIFICATE_BASE64" | base64 --decode -o "$CERT_PATH"
echo -n "$BUILD_PROVISION_PROFILE_BASE64" | base64 --decode -o "$PROFILE_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychain -d user -s "$KEYCHAIN_PATH"

mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/"

security cms -D -i "$PROFILE_PATH" > "$PROFILE_PLIST"
PROFILE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :Name' "$PROFILE_PLIST")
PROFILE_UUID=$(/usr/libexec/PlistBuddy -c 'Print :UUID' "$PROFILE_PLIST")

{
  echo "CI_KEYCHAIN_PATH=$KEYCHAIN_PATH"
  echo "CI_PROFILE_NAME=$PROFILE_NAME"
  echo "CI_PROFILE_UUID=$PROFILE_UUID"
} >> "$GITHUB_ENV"
