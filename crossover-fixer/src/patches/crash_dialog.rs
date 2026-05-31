/// Suppress Wine Crash Dialogs Patch
/// 
/// PROBLEM:
/// When Windows applications or games crash, freeze, or exit abnormally in a Wine bottle,
/// the built-in Wine debugger (`winedbg.exe`) launches an interactive crash dialog box.
/// Under macOS/CrossOver, this dialog prevents the crashed game processes from terminating
/// cleanly, hangs background services, and displays annoying, non-actionable dialog popups
/// on the screen.
/// 
/// FIX:
/// This patch sets `ShowCrashDialog` to `0` (disabled) under the registry key
/// `HKCU\Software\Wine\WineDbg`. This completely suppresses the interactive crash popups,
/// allowing crashed or hanging games to immediately terminate and exit cleanly back to CrossOver.

use winreg::enums::*;
use winreg::RegKey;
use std::io;
use crate::patches::Patch;

pub struct CrashDialogPatch;

impl Patch for CrashDialogPatch {
    fn id(&self) -> &'static str {
        "crash_dialog_fix"
    }

    fn name(&self) -> &'static str {
        "Suppress Wine Crash Dialogs"
    }

    fn description(&self) -> &'static str {
        "Suppresses standard Wine crash popups when exiting or running certain games."
    }

    fn is_enabled(&self) -> Result<bool, String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\WineDbg";
        let key = match hkcu.open_subkey(path) {
            Ok(k) => k,
            Err(_) => return Ok(false),
        };
        let val: io::Result<u32> = key.get_value("ShowCrashDialog");
        match val {
            Ok(v) => Ok(v == 0),
            Err(_) => Ok(false),
        }
    }

    fn enable(&self) -> Result<(), String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\WineDbg";
        let (key, _) = hkcu.create_subkey(path).map_err(|e| e.to_string())?;
        key.set_value("ShowCrashDialog", &0u32).map_err(|e| e.to_string())
    }

    fn disable(&self) -> Result<(), String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\WineDbg";
        let (key, _) = hkcu.create_subkey(path).map_err(|e| e.to_string())?;
        key.set_value("ShowCrashDialog", &1u32).map_err(|e| e.to_string())
    }
}
