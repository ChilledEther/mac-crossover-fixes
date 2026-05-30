# 🎮 macOS CrossOver Gamepad Fix Patcher

A lightweight, automated solution designed to resolve gamepad detection and controller mapping compatibility issues in modern Windows games running inside CodeWeavers CrossOver on macOS.

## 🔍 The Gamepad Detection Problem

Many modern Windows games built on the Unity engine use the modern **Unity Input System**, which queries the `Windows.Gaming.Input` API. Because Wine (powering CrossOver) exposes an incomplete stub implementation of this API on macOS, Unity's input engine fails to enumerate and detect any connected gamepads.

This patcher blocks the incomplete `windows.gaming.input` DLL in the Wine registry, forcing the Unity engine to bypass it and fall back to mature **XInput** and **DirectInput** standards, which map macOS gamepad inputs flawlessly via SDL.

## 🛠️ How to Install & Use

This repository offers two ways to use the patcher depending on your workflow.

### Method A: macOS Terminal Patcher Script (Recommended) 🚀

Run the native macOS script directly from your terminal. It auto-discovers your CrossOver bottles, checks their status, lets you toggle the fix, and manages automated installations in one command.

```bash
# Make the script executable
chmod +x scripts/gamepad-fix-patcher.sh

# Run in interactive mode
./scripts/gamepad-fix-patcher.sh
```

### Method B: Double-Clickable GUI Utility inside CrossOver 🖥️

You can install a lightweight, color-coded Windows utility compiled in Rust (`crossover-gamepad-fixer.exe`) that runs directly inside your CrossOver GUI as a program icon.

To automatically install this utility in a bottle with a single command (which sets up the binary, registers the shortcut, and syncs the beautiful controller-with-cross program icon in the CrossOver screen):

```bash
# Install the Rust utility in a specific bottle
./scripts/gamepad-fix-patcher.sh --install "Bottle Name"

# Or install in all active bottles
./scripts/gamepad-fix-patcher.sh --install all
```

*Note: Quit and relaunch CrossOver after installation to refresh the GUI program list icons.*

## 🤖 Agentic Setup

For automated or developer installation instructions using command-line flags, please refer to the [Agentic Install Guide](INSTALL.md).
