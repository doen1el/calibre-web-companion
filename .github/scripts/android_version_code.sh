#!/usr/bin/env bash
# Prints the versionCode that ends up inside the released APK. Two steps get
# applied to the pubspec build number on the way there:
#
#   base = <pubspec build number> * 10 + 3   (android/app/build.gradle.kts)
#   apk  = <abi> * 1000 + base               (Flutter, for --split-per-abi)
#          abi: 1 = armeabi-v7a, 2 = arm64-v8a, 4 = x86_64
#
# Fastlane changelogs are named after this number, because that is what F-Droid
# looks for: fastlane/metadata/android/<locale>/changelogs/<versionCode>.txt.
# F-Droid publishes the arm64-v8a build, hence ABI code 2.
set -euo pipefail

GRADLE_FILE="android/app/build.gradle.kts"
ABI_CODE="${ABI_CODE:-2}"

BUILD_NUMBER="${1:-}"
if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(sed -n -E 's/^version:[[:space:]]*.*\+([0-9]+).*/\1/p' pubspec.yaml)"
fi
[[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || { echo "Could not determine build number" >&2; exit 1; }

# Read the formula from Gradle instead of hardcoding it here
gradle_line="$(grep -E 'versionCode[[:space:]]*=[[:space:]]*flutter\.versionCode' "$GRADLE_FILE")"
multiplier="$(sed -n -E 's/.*flutter\.versionCode[[:space:]]*\*[[:space:]]*([0-9]+).*/\1/p' <<<"$gradle_line")"
offset="$(sed -n -E 's/.*\+[[:space:]]*([0-9]+).*/\1/p' <<<"$gradle_line")"

echo $((ABI_CODE * 1000 + BUILD_NUMBER * ${multiplier:-1} + ${offset:-0}))
