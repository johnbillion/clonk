#!/bin/bash

# Build the Swift app
echo "Building Clonk..."

# Create build directory
mkdir -p build

# Compile all Swift files
if swiftc Clonk/*.swift \
	-o build/Clonk \
	-framework AppKit \
	-framework SwiftUI \
	-target arm64-apple-macosx13.0 \
	-swift-version 5; then

	# Create app bundle structure
	APP_BUNDLE="build/Clonk.app"
	mkdir -p "$APP_BUNDLE/Contents/MacOS"
	mkdir -p "$APP_BUNDLE/Contents/Resources"

	# Move executable to app bundle
	mv build/Clonk "$APP_BUNDLE/Contents/MacOS/"

	# Copy Info.plist
	cp Clonk/Info.plist "$APP_BUNDLE/Contents/"

	# Copy app icon if it exists
	if [ -f "Clonk/AppIcon.icns" ]; then
		cp Clonk/AppIcon.icns "$APP_BUNDLE/Contents/Resources/"
		echo "✅ App icon added"
	else
		echo "⚠️  No app icon found (run ./create-icon.sh to generate one)"
	fi

	# Ad-hoc code sign to avoid Gatekeeper issues
	echo "Code signing app..."
	codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "⚠️  Code signing failed (continuing anyway)"

	echo "Build complete! Run with: open build/Clonk.app"
else
	echo "❌ Swift compilation failed"
fi
