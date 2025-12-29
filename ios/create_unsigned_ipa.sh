#!/bin/bash

set -e

echo "Starting unsigned IPA creation script..."

APP_NAME=$(grep 'name:' ../pubspec.yaml | head -n 1 | cut -d ':' -f 2 | tr -d ' ')

IPA_FILENAME="${APP_NAME}_unsigned.ipa"

echo "Building flutter app without code signing..."
flutter build ios --release --no-codesign

cd ../build/ios/iphoneos

echo "Packing the app into an unsigned IPA..."
rm -rf Payload
mkdir Payload

cp -r Runner.app Payload/

zip -r -q -y "$IPA_FILENAME" Payload

echo "The IPA file is stored here: $(pwd)/$IPA_FILENAME"