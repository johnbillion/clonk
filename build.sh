#!/bin/bash

# Build the Swift app
echo "Building Clonk..."

# Create build directory
mkdir -p build

# Compile all Swift files
swiftc Clonk/*.swift \
	-o build/Clonk \
	-framework AppKit \
	-framework SwiftUI \
	-target arm64-apple-macosx13.0 \
	-swift-version 5

# Create app bundle structure
APP_BUNDLE="build/Clonk.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Move executable to app bundle
mv build/Clonk "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp Clonk/Info.plist "$APP_BUNDLE/Contents/"

echo "Build complete! Run with: open build/Clonk.app"
