# 🤖 Agentic Installation Guide (crossover-gamepad-fixer)

This guide provides automated instructions for AI agents executing in this repository.

## 🛠️ Automated Setup

To query status, install, or uninstall the gamepad patcher programmatically:

### 1. Show Status
Query the status of the registry patch and the Rust GUI utility across all active bottles:
```bash
./scripts/gamepad-fix-patcher.sh --status
```

### 2. Install Rust GUI Utility
Automatically download the compiled `crossover-gamepad-fixer.exe` from GitHub, set up the directory structures, create the Windows Start Menu `.lnk` shortcut (which automatically extracts the embedded gamepad icon), and synchronize menus:
* **All Bottles**:
  ```bash
  ./scripts/gamepad-fix-patcher.sh --install all
  ```
* **Specific Bottle**:
  ```bash
  ./scripts/gamepad-fix-patcher.sh --install "Steam"
  ```

### 3. Uninstall and Restore Bottle
Revert all DLL registry overrides and remove all files, shortcuts, and macOS app bundles completely:
* **All Bottles**:
  ```bash
  ./scripts/gamepad-fix-patcher.sh --uninstall all
  ```
* **Specific Bottle**:
  ```bash
  ./scripts/gamepad-fix-patcher.sh --uninstall "Steam"
  ```

## 📂 Directory Layout

The automated setup performs the following actions inside the bottle:
* **Binary Location**: `/Users/jarredroberts/Library/Application Support/CrossOver/Bottles/{Bottle}/drive_c/Games/crossover-gamepad-fixer.exe`
* **Shortcut Location**: `/Users/jarredroberts/Library/Application Support/CrossOver/Bottles/{Bottle}/drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Toggle Gamepad Fix.lnk`
* **macOS Wrapper**: `~/Applications/CrossOver/Toggle Gamepad Fix ({Bottle}).app`
