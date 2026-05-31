use winreg::enums::*;
use winreg::RegKey;
use std::io;

pub trait Patch {
    fn id(&self) -> &'static str;
    fn name(&self) -> &'static str;
    fn description(&self) -> &'static str;
    fn is_enabled(&self) -> Result<bool, String>;
    fn enable(&self) -> Result<(), String>;
    fn disable(&self) -> Result<(), String>;
}

pub struct GamepadPatch;

impl Patch for GamepadPatch {
    fn id(&self) -> &'static str {
        "gamepad_fix"
    }

    fn name(&self) -> &'static str {
        "Unity Gamepad Support"
    }

    fn description(&self) -> &'static str {
        "Blocks windows.gaming.input DLL so Unity engine games fall back to XInput/DirectInput gamepad detection."
    }

    fn is_enabled(&self) -> Result<bool, String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\DllOverrides";
        let key = match hkcu.open_subkey(path) {
            Ok(k) => k,
            Err(_) => return Ok(false),
        };
        let val: io::Result<String> = key.get_value("windows.gaming.input");
        match val {
            Ok(s) => Ok(s == ""),
            Err(_) => Ok(false),
        }
    }

    fn enable(&self) -> Result<(), String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\DllOverrides";
        let (key, _) = hkcu.create_subkey(path).map_err(|e| e.to_string())?;
        key.set_value("windows.gaming.input", &"").map_err(|e| e.to_string())
    }

    fn disable(&self) -> Result<(), String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\DllOverrides";
        if let Ok(key) = hkcu.open_subkey_with_flags(path, KEY_SET_VALUE) {
            let _ = key.delete_value("windows.gaming.input");
        }
        Ok(())
    }
}

pub struct DWritePatch;

impl Patch for DWritePatch {
    fn id(&self) -> &'static str {
        "dwrite_fix"
    }

    fn name(&self) -> &'static str {
        "DirectWrite Blank Text Fix"
    }

    fn description(&self) -> &'static str {
        "Disables DirectWrite to fix missing or invisible text in game launchers like Steam or EA Desktop."
    }

    fn is_enabled(&self) -> Result<bool, String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\DllOverrides";
        let key = match hkcu.open_subkey(path) {
            Ok(k) => k,
            Err(_) => return Ok(false),
        };
        let val: io::Result<String> = key.get_value("dwrite");
        match val {
            Ok(s) => Ok(s == ""),
            Err(_) => Ok(false),
        }
    }

    fn enable(&self) -> Result<(), String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\DllOverrides";
        let (key, _) = hkcu.create_subkey(path).map_err(|e| e.to_string())?;
        key.set_value("dwrite", &"").map_err(|e| e.to_string())
    }

    fn disable(&self) -> Result<(), String> {
        let hkcu = RegKey::predef(HKEY_CURRENT_USER);
        let path = "Software\\Wine\\DllOverrides";
        if let Ok(key) = hkcu.open_subkey_with_flags(path, KEY_SET_VALUE) {
            let _ = key.delete_value("dwrite");
        }
        Ok(())
    }
}

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

pub fn get_all_patches() -> Vec<Box<dyn Patch>> {
    vec![
        Box::new(GamepadPatch),
        Box::new(DWritePatch),
        Box::new(CrashDialogPatch),
    ]
}
