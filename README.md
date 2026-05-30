# 🎮 macOS CrossOver Compatibility Fixes & Scripts

A collection of registry patches, automated tools, and helper scripts designed to resolve compatibility issues and enhance the gaming experience when running Windows applications inside CodeWeavers CrossOver on macOS.

Currently, the primary fix included is the **Gamepad Detection & Initialization Fix** for modern Unity-based games (such as *Cairn*, *Valheim*, *Genshin Impact*, etc.).

## 🔍 The Gamepad Detection Problem

Many modern Windows games built on recent versions of the Unity engine use the modern **Unity Input System**. When initializing, these games look for a modern Windows API called `Windows.Gaming.Input`.

* **The Root Cause**: Wine (which runs behind the scenes in CrossOver) has an incomplete, experimental stub implementation of the WinRT-based `Windows.Gaming.Input` API. Because this API is incomplete on macOS, Unity's input engine fails to enumerate and detect any connected gamepads, defaulting to keyboard and mouse only.
* **The Solution**: By explicitly disabling the `windows.gaming.input` library (DLL) in the Wine registry, we force the Unity game engine to bypass this modern WinRT API entirely and fall back to the robust, fully mature `XInput` and `DirectInput` APIs. These legacy APIs handle macOS gamepad inputs flawlessly via SDL translation.

### ⚠️ Potential Side Effects

Disabling the `windows.gaming.input` API is extremely safe and has minimal side effects:
* **Fallback to XInput**: Virtually all Windows games support `XInput` (the Xbox controller standard) and/or `DirectInput` natively. Falling back to these standards is the default behavior, restoring full gamepad support.
* **Advanced Haptics**: You will lose support for advanced controller features like *Impulse Triggers* (rumble motors inside the trigger buttons on Xbox controllers). However, since macOS does not natively pass impulse trigger signals to controllers anyway, you lose nothing in practice.
* **Microsoft Store Games**: If you run modern UWP (Universal Windows Platform) games that exclusively use WinRT input APIs, they might fail to recognize controllers. Since CrossOver is designed primarily for standard Win32 games (Steam, GOG, Epic Games), this is highly unlikely to affect your library.

## 🛠️ How to Apply the Fixes

This repository offers three different methods to apply the gamepad fix depending on your preferred workflow.

### Method A: Interactive macOS Host Script (Recommended) 🚀

This repository includes a native macOS shell script (`gamepad-fix-patcher.sh`) that runs on your macOS terminal. It automatically scans your system for CrossOver bottles, shows the active status of each bottle, lets you toggle the fix, installs/uninstalls the Rust utility, and manages simulated reboots.

#### Usage
1. Clone or download this repository to your Mac.
2. Open Terminal and navigate to the directory.
3. Make the script executable and run it:
   ```bash
   chmod +x scripts/gamepad-fix-patcher.sh
   ./scripts/gamepad-fix-patcher.sh [FLAGS]
   ```

#### Supported Flags
*   `--status`             - Lists the patch and Rust utility installation status for all active bottles.
*   `--install [BOTTLE]`   - Automatically installs the Rust GUI utility inside the specified bottle (or `all`). If no bottle is specified, it opens an interactive selector.
*   `--uninstall [BOTTLE]` - Uninstalls the fix and Rust utility, removing all desktop/menu shortcuts and restoring the registry of the specified bottle (or `all`) to defaults.
*   `-h, --help`           - Shows the help documentation.

### Method B: Lightweight Windows Utility (Rust) 🦀

This repository also includes a native Windows command-line utility compiled in Rust (`crossover-gamepad-fixer.exe`) that runs directly inside your Wine bottle. It displays `ENABLED` in bright green if the patch is active and `DISABLED` in bright red if default behavior is active, asking for confirmation before toggling.

#### Automatic Installation (Recommended)
You do not need to compile or download this manually. Simply run the native macOS script on your terminal:
```bash
./scripts/gamepad-fix-patcher.sh --install [BOTTLE_NAME]
```
This automatically downloads the latest compiled binary release from GitHub, places it inside the selected bottle's `C:\Games\crossover-gamepad-fixer.exe` alongside the custom gamepad medical icon, creates the Windows shortcut, synchronizes CrossOver, generates hicolor GUI icons, and patches CrossOver's database to immediately show the beautiful gamepad-with-cross icon on your CrossOver GUI bottle screen.

#### Manual Installation
1. Download the compiled `crossover-gamepad-fixer.exe` from the latest GitHub Release.
2. Put the executable inside your bottle's virtual C: drive (e.g. at `C:\Games\crossover-gamepad-fixer.exe`).
3. Create a Start Menu shortcut for it in CrossOver pointing to `wineconsole.exe` wrapping the binary, or run it using CrossOver's **Run Command** tool.

## ⚡ Important Best Practices

* **Connection Order**: Always connect your controller to your Mac **before** starting CrossOver or launching the game. Wine scans for input devices only during initialization. If you connect your gamepad after starting the game, it may not be recognized.
* **Simulate Reboot**: If a game was already running or CrossOver processes were active in the background, you must click **Simulate Reboot** in the CrossOver sidebar to reload the registry and apply the DLL override.
