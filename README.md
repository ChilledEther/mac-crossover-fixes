# 🎮 macOS CrossOver Fixer

A lightweight, automated, and modular compatibility suite designed to resolve gamepad detection, text rendering, and crash popup issues in modern Windows games and launchers running inside CodeWeavers CrossOver on macOS.

## 🔍 Supported Compatibility Patches

This utility manages several common registry and DLL patches dynamically to optimize your CrossOver bottle performance and compatibility:

1. **Unity Gamepad Support**: Blocks the incomplete `windows.gaming.input` DLL in the Wine registry, forcing the Unity engine to bypass it and fall back to mature **XInput** and **DirectInput** standards, which map macOS gamepad inputs flawlessly via SDL.
2. **DirectWrite Blank Text Fix**: Disables DirectWrite rendering in Wine (`dwrite=""` override) to fix missing, blank, or invisible text in standard gaming storefronts and launchers such as Steam, EA Desktop, and Ubisoft Connect.
3. **Suppress Wine Crash Dialogs**: Alters the WineDbg crash feedback setting (`ShowCrashDialog=0`) to prevent annoying, non-actionable Wine crash popups from disrupting your gameplay or bottle exit.

> [!NOTE]
> **Tested Hardware & Verification**: The gamepad fix was verified using an **8BitDo Pro 3** controller. The initial symptom was a complete lack of gamepad detection inside the Unity game (only mouse and keyboard options were active). After applying this patcher and disabling the `windows.gaming.input` DLL override, the controller was immediately detected and fully usable.

## 🛠️ How to Install & Use

This repository offers two ways to use the patcher depending on your workflow.

### Method A: macOS Terminal Patcher Script (Recommended) 🚀

Run the native macOS script directly from your terminal. It auto-discovers your CrossOver bottles, lists the status of all patches, lets you toggle them dynamically, and manages automated installations in one command.

```bash
# Make the script executable
chmod +x scripts/gamepad-fix-patcher.sh

# Run in interactive mode
./scripts/gamepad-fix-patcher.sh
```

### Method B: Double-Clickable Control Panel inside CrossOver 🖥️

You can install a lightweight, modular Windows control panel utility compiled in Rust (`crossover-gamepad-fixer.exe`) that runs directly inside your CrossOver GUI as a program icon named **CrossOver Fixer**. It gives you a sleek graphical checklist to toggle patches on and off directly on the screen.

To automatically install this control panel in a bottle with a single command (which sets up the binary, registers the shortcut, and syncs the program icon in the CrossOver screen):

```bash
# Install the Rust utility in a specific bottle
./scripts/gamepad-fix-patcher.sh --install "Bottle Name"

# Or install in all active bottles
./scripts/gamepad-fix-patcher.sh --install all
```

*Note: Quit and relaunch CrossOver after installation to refresh the GUI program list icons.*

## 🤖 Agentic Setup

For automated or developer installation instructions using command-line flags, please refer to the [Agentic Install Guide](INSTALL.md).

