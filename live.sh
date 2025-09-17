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

# Watch and rebuild on changes (with directory monitoring for new files)
while true; do
	find Clonk -name "*.swift" -o -name "*.plist" | entr -d -n -r sh -c '
		echo "🔄 Rebuilding at $(date)..."
		# Kill ALL instances before rebuilding
		pkill -9 -f "Clonk" 2>/dev/null || true
		pkill -9 -f "build/Clonk.app" 2>/dev/null || true
		sleep 0.5
		./build.sh && {
			echo "✅ Build complete at $(date), restarting app..."
			sleep 0.5
			./build/Clonk.app/Contents/MacOS/Clonk &
			echo "👀 Watching for changes..."
		} || echo "❌ Build failed at $(date)"
	'
	echo "📁 Directory changed, rescanning for new files..."
	sleep 1
done
