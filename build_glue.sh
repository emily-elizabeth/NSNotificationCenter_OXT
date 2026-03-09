#!/bin/bash
# Build NSNotificationGlue.dylib and install it into the LCB extension folder.
# Run this script from the directory containing NSNotificationGlue.m
# Usage: ./build_glue.sh /path/to/org.openxtalk.nsnotificationcenter

set -e

EXTENSION_DIR="${1:-.}"

echo "Building arm64..."
clang -x objective-c -dynamiclib -framework Foundation -framework AppKit \
  -arch arm64 \
  -fobjc-arc \
  -o NSNotificationGlue_arm64.dylib NSNotificationGlue.m

echo "Building x86_64..."
clang -x objective-c -dynamiclib -framework Foundation -framework AppKit \
  -arch x86_64 \
  -fobjc-arc \
  -o NSNotificationGlue_x86_64.dylib NSNotificationGlue.m

echo "Creating universal binary..."
lipo -create NSNotificationGlue_arm64.dylib NSNotificationGlue_x86_64.dylib \
  -output NSNotificationGlue.dylib

echo "Installing..."
mkdir -p "$EXTENSION_DIR/code/x86_64-mac"
mkdir -p "$EXTENSION_DIR/code/arm64-mac"
cp NSNotificationGlue.dylib "$EXTENSION_DIR/code/x86_64-mac/NSNotificationGlue.dylib"
cp NSNotificationGlue.dylib "$EXTENSION_DIR/code/arm64-mac/NSNotificationGlue.dylib"

# Cleanup intermediates
rm NSNotificationGlue_arm64.dylib NSNotificationGlue_x86_64.dylib

echo "Done! Dylib installed to:"
echo "  $EXTENSION_DIR/code/x86_64-mac/NSNotificationGlue.dylib"
echo "  $EXTENSION_DIR/code/arm64-mac/NSNotificationGlue.dylib"
