# 🤖 Agentic Installation Guide (macOS CrossOver Fixer)

This guide provides automated instructions for AI agents executing in this repository.

## 🛠️ Automated Setup

To query status, install, or uninstall the CrossOver Fixer programmatically:

### 1. Show Status
Query the status of all compatibility patches and the Rust GUI control panel across all active bottles:
```bash
./scripts/gamepad-fix-patcher.sh --status
```

### 2. Install Rust GUI Control Panel
Automatically download the compiled `crossover-fixer.exe` from GitHub, set up the directory structures, create the Windows Start Menu `.lnk` shortcut (which automatically extracts the embedded icon), and synchronize menus:
* **All Bottles**:
  ```bash
  ./scripts/gamepad-fix-patcher.sh --install all
  ```
* **Specific Bottle**:
  ```bash
  ./scripts/gamepad-fix-patcher.sh --install "Steam"
  ```

### 3. Uninstall and Restore Bottle
Revert all DLL and registry overrides and remove all files, shortcuts, and macOS app bundles completely:
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
* **Binary Location**: `/Users/jarredroberts/Library/Application Support/CrossOver/Bottles/{Bottle}/drive_c/Utilities/crossover-fixer.exe`
* **Shortcut Location**: `/Users/jarredroberts/Library/Application Support/CrossOver/Bottles/{Bottle}/drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/CrossOver Fixer.lnk`
* **macOS Wrapper**: `~/Applications/CrossOver/CrossOver Fixer.app`

