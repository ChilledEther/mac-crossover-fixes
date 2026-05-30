#![windows_subsystem = "windows"]

use std::ffi::OsStr;
use std::os::windows::ffi::OsStrExt;
use winreg::enums::*;
use winreg::RegKey;

#[link(name = "user32")]
extern "system" {
    fn MessageBoxW(
        hWnd: *mut std::ffi::c_void,
        lpText: *const u16,
        lpCaption: *const u16,
        uType: u32,
    ) -> i32;
}

const MB_YESNO: u32 = 0x00000004;
const MB_ICONQUESTION: u32 = 0x00000020;
const MB_ICONINFORMATION: u32 = 0x00000040;
const IDYES: i32 = 6;

fn to_wide(s: &str) -> Vec<u16> {
    OsStr::new(s)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect()
}

fn show_message_box(text: &str, caption: &str, utype: u32) -> i32 {
    let wide_text = to_wide(text);
    let wide_caption = to_wide(caption);
    unsafe {
        MessageBoxW(
            std::ptr::null_mut(),
            wide_text.as_ptr(),
            wide_caption.as_ptr(),
            utype,
        )
    }
}

fn main() {
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let path = "Software\\Wine\\DllOverrides";

    // Open or create the subkey
    let (key, _) = match hkcu.create_subkey(path) {
        Ok(k) => k,
        Err(e) => {
            show_message_box(
                &format!("Error opening registry key: {}", e),
                "Error - Gamepad Fix Toggler",
                MB_ICONINFORMATION,
            );
            return;
        }
    };

    // Query the windows.gaming.input registry value
    let value_res: std::io::Result<String> = key.get_value("windows.gaming.input");
    let is_enabled = match value_res {
        Ok(val) => val == "",
        Err(_) => false,
    };

    // Prepare status text
    let status_msg = if is_enabled {
        "Current Status: ENABLED (windows.gaming.input is blocked)\n\nWould you like to DISABLE the gamepad fix (restore default Wine behavior)?"
    } else {
        "Current Status: DISABLED (Default Wine input behavior)\n\nWould you like to ENABLE the gamepad fix (block windows.gaming.input)?"
    };

    // Show status toggler dialog
    let response = show_message_box(
        status_msg,
        "Toggle Gamepad Fix",
        MB_YESNO | MB_ICONQUESTION,
    );

    if response == IDYES {
        if is_enabled {
            match key.delete_value("windows.gaming.input") {
                Ok(_) => {
                    show_message_box(
                        "Success! Gamepad fix has been DISABLED.\n\nPlease reboot this bottle inside CrossOver to apply changes to running games.",
                        "Success - Gamepad Fix Toggler",
                        MB_ICONINFORMATION,
                    );
                }
                Err(e) => {
                    show_message_box(
                        &format!("Error removing registry value: {}", e),
                        "Error - Gamepad Fix Toggler",
                        MB_ICONINFORMATION,
                    );
                }
            }
        } else {
            match key.set_value("windows.gaming.input", &"") {
                Ok(_) => {
                    show_message_box(
                        "Success! Gamepad fix has been ENABLED.\n\nPlease reboot this bottle inside CrossOver to apply changes to running games.",
                        "Success - Gamepad Fix Toggler",
                        MB_ICONINFORMATION,
                    );
                }
                Err(e) => {
                    show_message_box(
                        &format!("Error setting registry value: {}", e),
                        "Error - Gamepad Fix Toggler",
                        MB_ICONINFORMATION,
                    );
                }
            }
        }
    }
}
