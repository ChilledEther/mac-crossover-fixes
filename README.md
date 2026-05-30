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

This repository includes a native macOS shell script (`toggle-gamepad-fix.sh`) that runs on your macOS terminal. It automatically scans your system for CrossOver bottles, shows the active status of each bottle, lets you toggle the fix instantly, and triggers a simulated reboot of the bottle to apply changes.

1. Clone or download this repository to your Mac.
2. Open Terminal and navigate to the directory.
3. Make the script executable and run it:
   ```bash
   chmod +x scripts/toggle-gamepad-fix.sh
   ./scripts/toggle-gamepad-fix.sh
   ```
4. Follow the interactive menu to select your bottle and toggle the patch.

### Method B: Double-Click Registry Files 📄

If you prefer applying the registry patches directly using CrossOver's built-in registry editor:

1. In CrossOver, select the bottle you want to apply the fix to.
2. In the right panel, click **Run Command**.
3. Type `regedit` and click **Run**.
4. In the Registry Editor window, click **Registry** in the top menu -> **Import Registry File...**.
5. Select one of the `.reg` files from the `registry/` folder in this repository:
   * `disable-windows-gaming-input.reg`: Enables the gamepad detection fix.
   * `enable-windows-gaming-input.reg`: Disables the fix (restores default Wine behavior).
6. Close the Registry Editor.
7. Click **Simulate Reboot** in CrossOver to apply the changes.

### Method C: One-Click GUI Launcher inside CrossOver 🖥️

You can create an interactive launcher utility that lives directly on your CrossOver UI (under your program icons) to toggle the fix on/off anytime with a double-click.

#### Step 1: Copy the Toggler Batch File
Copy the `scripts/ToggleGamepadFix.bat` file to a folder inside your bottle's virtual C: drive (for example, `C:\Games\ToggleGamepadFix.bat`).
* *Tip: You can access the C: drive by selecting your bottle in CrossOver and clicking **Open C: Drive**.*

#### Step 2: Generate a Start Menu Shortcut
To make CrossOver notice the script, you must create a standard Windows shortcut inside the bottle's Start Menu that targets `wineconsole.exe` wrapping the batch file:

1. Copy the `scripts/CreateShortcut.vbs` file to your bottle's virtual C: drive (e.g. `C:\CreateShortcut.vbs`).
2. Run a command inside your bottle using CrossOver's **Run Command** tool:
   ```text
   cscript.exe "C:\CreateShortcut.vbs" "Toggle Gamepad Fix" "C:\Games\ToggleGamepadFix.bat"
   ```
3. Delete the `CreateShortcut.vbs` file from your virtual C: drive once done.

#### Step 3: Synchronize CrossOver Menus
In CrossOver, click **Simulate Reboot** or restart CrossOver. The new **Toggle Gamepad Fix** application will automatically appear as a double-clickable program icon in your bottle's list. Double-clicking it opens a console showing the current status and toggling it instantly.

### Method D: Lightweight Windows Utility (Rust) 🦀

This repository also includes a native Windows command-line utility compiled in Rust (`crossover-gamepad-fixer.exe`) that runs directly inside your Wine bottle.

* **Color-Coded Status**: Displays `ENABLED` in bright green if the patch is active, and `DISABLED` in bright red if default behavior is active.
* **Interactive Toggle**: Prompts you to confirm before executing the registry modification.
* **GitHub Actions Workflow**: Automatically compiled and packaged on every commit.

#### How to Use
1. Download the compiled `crossover-gamepad-fixer.exe` from the latest GitHub Actions workflow run artifacts or compile it yourself (`cargo build --release`).
2. Put the executable inside your bottle (e.g. at `C:\Games\crossover-gamepad-fixer.exe`).
3. Create a Start Menu shortcut for it in CrossOver to launch it with a double-click, or run it using CrossOver's **Run Command** tool.

## ⚡ Important Best Practices

* **Connection Order**: Always connect your controller to your Mac **before** starting CrossOver or launching the game. Wine scans for input devices only during initialization. If you connect your gamepad after starting the game, it may not be recognized.
* **Simulate Reboot**: If a game was already running or CrossOver processes were active in the background, you must click **Simulate Reboot** in the CrossOver sidebar to reload the registry and apply the DLL override.
