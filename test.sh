#!/bin/bash

echo "Running Clonk tests..."

# Build the app first
echo "Building app..."
./build.sh

if [ $? -ne 0 ]; then
	echo "❌ Build failed"
	exit 1
fi

echo "✅ Build successful"

# Run Swift Package Manager tests
echo "Running unit tests..."
swift run ClonkTests

if [ $? -ne 0 ]; then
	echo "❌ Unit tests failed"
	exit 1
fi

echo "✅ Unit tests passed"

# Check if app bundle was created correctly
if [ -f "build/Clonk.app/Contents/MacOS/Clonk" ]; then
	echo "✅ App bundle created successfully"
else
	echo "❌ App bundle not found"
	exit 1
fi

# Test that the app can launch (basic smoke test)
echo "Running smoke test..."
./build/Clonk.app/Contents/MacOS/Clonk &
APP_PID=$!

sleep 2

if kill -0 $APP_PID 2>/dev/null; then
	echo "✅ App launched successfully"
	kill $APP_PID
	# Give it time to terminate
	sleep 1
else
	echo "❌ App failed to launch"
	exit 1
fi

echo "🎉 All tests passed!"
