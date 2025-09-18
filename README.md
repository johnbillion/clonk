# Clonk

A macOS menu bar app that displays the current time and shows a delicious calendar popup when clicked.

## Installing

Download `Clonk.dmg` from [the latest release](https://github.com/johnbillion/clonk/releases) and install it like any other app. Clonk is currently not signed, so the first time you attempt to open the app macOS will prevent it from opening and show you a warning. Visit System Settings -> Privacy & Security, scroll down, and you'll see a message about Clonk and an option to allow it to run. Allow it and the open the app again and you'll be good to go.

Visit System Settings -> Control Centre, scroll down and click Clock Options, then choose Analogue for the menu bar clock style. This is the only way to minimise the clock in the menu bar on macOS, there is no way to fully hide it.

## Building and Running

### Option 1: Command Line (No Xcode Required)

**Prerequisites:**
- macOS 14.0 or later
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
