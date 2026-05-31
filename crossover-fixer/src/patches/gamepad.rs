use winreg::enums::*;
use winreg::RegKey;
use std::io;
use crate::patches::Patch;

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
