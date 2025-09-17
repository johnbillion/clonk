#!/bin/bash

echo "🔴 Live reload enabled - edit Swift files to trigger rebuild"

# Install entr if not available
if ! command -v entr &> /dev/null; then
	echo "Installing entr..."
	if command -v brew &> /dev/null; then
		brew install entr
	else
		echo "❌ Please install Homebrew first"
		exit 1
	fi
fi

# Kill any existing instances first
pkill -f Clonk 2>/dev/null || true
sleep 1

# Initial build
./build.sh && {
	echo "Starting Clonk..."
	./build/Clonk.app/Contents/MacOS/Clonk &
}

# Watch and rebuild on changes
find Clonk -name "*.swift" | entr -n -r sh -c '
	echo "🔄 Rebuilding..."
	# Kill ALL instances before rebuilding
	pkill -9 -f Clonk 2>/dev/null || true
	sleep 1
	./build.sh && {
		echo "✅ Build complete, restarting app..."
		./build/Clonk.app/Contents/MacOS/Clonk &
		echo "👀 Watching for changes..."
	} || echo "❌ Build failed"
'
