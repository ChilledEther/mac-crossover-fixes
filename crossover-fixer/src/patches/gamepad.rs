/// Unity Gamepad Support Patch
/// 
/// PROBLEM:
/// Modern Windows games built on the Unity engine use the modern Unity Input System,
/// which queries the `Windows.Gaming.Input` API. Because Wine (powering CrossOver)
/// exposes an incomplete stub implementation of this API on macOS, Unity's input
/// engine fails to enumerate and detect any connected gamepads.
/// 
/// FIX:
/// This patch blocks the incomplete `windows.gaming.input` DLL in the Wine registry
/// by setting a DLL override value of `""` (disabled). This forces the Unity engine
/// to bypass it and fall back to mature, well-supported `XInput` and `DirectInput`
/// standards, which map macOS gamepad inputs perfectly via SDL.

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
