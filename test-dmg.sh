#!/bin/bash

# Test that the DMG works correctly
# Usage: ./test-dmg.sh

set -e

DMG_NAME="Clonk.dmg"

# Check if DMG exists
if [ ! -f "${DMG_NAME}" ]; then
    echo "Error: ${DMG_NAME} not found. Please run create-dmg.sh first."
    exit 1
fi

echo "Testing ${DMG_NAME}..."

# Create a unique mount point
MOUNT_POINT="/tmp/clonk-test-$$"

# Mount the DMG
echo "Mounting DMG to ${MOUNT_POINT}..."
hdiutil attach "${DMG_NAME}" -mountpoint "${MOUNT_POINT}" -nobrowse

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up..."
    if [ -d "${MOUNT_POINT}" ]; then
        hdiutil detach "${MOUNT_POINT}" -quiet || true
    fi
}
trap cleanup EXIT

# Verify contents
echo "Verifying DMG contents..."
echo -n "  Checking for Clonk.app... "
if [ -d "${MOUNT_POINT}/Clonk.app" ]; then
    echo "✅"
else
    echo "❌ Not found"
    exit 1
fi

echo -n "  Checking for Applications symlink... "
if [ -L "${MOUNT_POINT}/Applications" ]; then
    echo "✅"
else
    echo "❌ Not found"
    exit 1
fi

echo -n "  Checking app bundle structure... "
if [ -f "${MOUNT_POINT}/Clonk.app/Contents/MacOS/Clonk" ]; then
    echo "✅"
else
    echo "❌ Executable not found"
    exit 1
fi

echo -n "  Checking Info.plist... "
if [ -f "${MOUNT_POINT}/Clonk.app/Contents/Info.plist" ]; then
    echo "✅"
else
    echo "❌ Info.plist not found"
    exit 1
fi

# Test the app binary
echo "Testing app launch..."
"${MOUNT_POINT}/Clonk.app/Contents/MacOS/Clonk" &
APP_PID=$!

# Wait a bit for app to start
sleep 2

# Check if app is still running
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ App launched successfully"
    
    # Kill the test app
    kill $APP_PID 2>/dev/null || true
    wait $APP_PID 2>/dev/null || true
else
    echo "❌ App failed to launch"
    exit 1
fi

# Verify DMG is read-only
echo -n "Verifying DMG is read-only... "
if touch "${MOUNT_POINT}/test-file" 2>/dev/null; then
    echo "❌ DMG is writable (should be read-only)"
    rm "${MOUNT_POINT}/test-file"
    exit 1
else
    echo "✅"
fi

echo ""
echo "✅ All DMG tests passed!"