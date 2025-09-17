# Clonk

A macOS menu bar app that displays the current time and shows a delicious calendar popup when clicked.

## Building and Running

### Option 1: Command Line (No Xcode Required)

**Prerequisites:**
- macOS 13.0 or later
- Command Line Tools for Xcode: `xcode-select --install`

**Build and run:**
```bash
cd Clonk
./build.sh
open build/Clonk.app
```

**Development:**
```bash
# Live reload (auto rebuild on file changes)
./live.sh
```

**Using Swift Package Manager:**
```bash
swift build
swift run Clonk
```

### Option 2: Xcode

1. Open `Clonk.xcodeproj` in Xcode
2. Select your development team in the project settings (if needed for code signing)
3. Build and run (⌘+R)
4. The app will appear in your menu bar showing the current time
5. Click the time to see the calendar
