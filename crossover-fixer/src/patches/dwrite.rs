use winreg::enums::*;
use winreg::RegKey;
use std::io;
use crate::patches::Patch;

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
