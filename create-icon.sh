#!/bin/bash

# Create icon from SVG
echo "Creating app icon from SVG..."

# Check if we have the required tools
if ! command -v rsvg-convert &> /dev/null; then
    echo "rsvg-convert not found. Installing with Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew not found. Please install rsvg-convert manually or use an online SVG to PNG converter."
        echo "You can convert icon.svg to the following PNG sizes and place them in Clonk/AppIcon.iconset/:"
        echo "  icon_16x16.png (16x16)"
        echo "  icon_16x16@2x.png (32x32)"
        echo "  icon_32x32.png (32x32)"
        echo "  icon_32x32@2x.png (64x64)"
        echo "  icon_128x128.png (128x128)"
        echo "  icon_128x128@2x.png (256x256)"
        echo "  icon_256x256.png (256x256)"
        echo "  icon_256x256@2x.png (512x512)"
        echo "  icon_512x512.png (512x512)"
        echo "  icon_512x512@2x.png (1024x1024)"
        exit 1
    fi
    brew install librsvg
fi

# Create iconset directory
mkdir -p Clonk/AppIcon.iconset

# Generate all required icon sizes
sizes=(16 32 64 128 256 512 1024)
names=(
    "icon_16x16.png"
    "icon_16x16@2x.png"
    "icon_32x32.png"
    "icon_32x32@2x.png"
    "icon_128x128.png"
    "icon_128x128@2x.png"
    "icon_256x256.png"
    "icon_256x256@2x.png"
    "icon_512x512.png"
    "icon_512x512@2x.png"
)

for i in "${!sizes[@]}"; do
    size=${sizes[$i]}
    name=${names[$i]}
    echo "Generating ${name} (${size}x${size})..."
    rsvg-convert -w $size -h $size icon.svg > "Clonk/AppIcon.iconset/${name}"
done

# Create the .icns file
echo "Creating AppIcon.icns..."
iconutil -c icns Clonk/AppIcon.iconset -o Clonk/AppIcon.icns

echo "✅ Icon created successfully!"
echo "AppIcon.icns is ready for use in the app bundle."