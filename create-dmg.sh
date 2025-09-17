#!/bin/bash

# Create a DMG from the built Clonk.app
# Usage: ./create-dmg.sh

set -e

# Check if app exists
if [ ! -d "build/Clonk.app" ]; then
	echo "Error: build/Clonk.app not found. Please run build.sh first."
	exit 1
fi

DMG_NAME="Clonk.dmg"
VOLUME_NAME="Clonk"
echo "Creating DMG: ${DMG_NAME}"

# Create a temporary directory for DMG contents
DMG_TEMP="dmg_contents"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"

# Copy the app to the temporary directory
echo "Copying Clonk.app..."
cp -R build/Clonk.app "${DMG_TEMP}/"

# Create a symbolic link to Applications folder
echo "Creating Applications symlink..."
ln -s /Applications "${DMG_TEMP}/Applications"

# Remove existing DMG if it exists
rm -f "${DMG_NAME}"

# Create DMG with compression
echo "Creating DMG..."
hdiutil create -volname "${VOLUME_NAME}" \
	-srcfolder "${DMG_TEMP}" \
	-ov \
	-format UDZO \
	"${DMG_NAME}"

# Clean up
rm -rf "${DMG_TEMP}"

# Show result
echo "✅ DMG created successfully: ${DMG_NAME}"
ls -lh "${DMG_NAME}"

# Verify the DMG
echo "Verifying DMG..."
hdiutil verify "${DMG_NAME}"

echo "Done!"
