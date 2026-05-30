use std::io::{self, Write};
use winreg::enums::*;
use winreg::RegKey;

fn main() {
    println!("\x1b[1m\x1b[36m===================================================\x1b[0m");
    println!("\x1b[1m\x1b[36m   CrossOver Gamepad Detection Patch Toggler (Rust)\x1b[0m");
    println!("\x1b[1m\x1b[36m===================================================\x1b[0m");
    println!();

    let hkcu = RegKey::predefined(HKEY_CURRENT_USER);
    let path = "Software\\Wine\\DllOverrides";

    // Open or create the subkey
    let (key, _) = match hkcu.create_subkey(path) {
        Ok(k) => k,
        Err(e) => {
            println!("\x1b[1m\x1b[31mError opening registry key: {}\x1b[0m", e);
            pause();
            return;
        }
    };

    // Query the windows.gaming.input registry value
    let value_res: io::Result<String> = key.get_value("windows.gaming.input");
    let is_enabled = match value_res {
        Ok(val) => val == "",
        Err(_) => false,
    };

    // Print the current status with requested colors
    if is_enabled {
        println!("Current Status: \x1b[1m\x1b[32mENABLED\x1b[0m (windows.gaming.input is overridden & blocked)");
    } else {
        println!("Current Status: \x1b[1m\x1b[31mDISABLED\x1b[0m (Default Wine input behavior)");
    }
    println!();

    print!("Would you like to toggle this fix? (y/N): ");
    io::stdout().flush().unwrap();

    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap();
    let choice = input.trim().to_lowercase();

    if choice == "y" || choice == "yes" {
        if is_enabled {
            println!("Disabling gamepad fix (restoring default behavior)...");
            match key.delete_value("windows.gaming.input") {
                Ok(_) => {
                    println!();
                    println!("\x1b[1m\x1b[32mSuccess! Gamepad fix has been DISABLED.\x1b[0m");
                }
                Err(e) => {
                    println!();
                    println!("\x1b[1m\x1b[31mError removing registry value: {}\x1b[0m", e);
                }
            }
        } else {
            println!("Enabling gamepad fix (blocking windows.gaming.input)...");
            match key.set_value("windows.gaming.input", &"") {
                Ok(_) => {
                    println!();
                    println!("\x1b[1m\x1b[32mSuccess! Gamepad fix has been ENABLED.\x1b[0m");
                }
                Err(e) => {
                    println!();
                    println!("\x1b[1m\x1b[31mError setting registry value: {}\x1b[0m", e);
                }
            }
        }
        println!();
        println!("Please reboot this bottle inside CrossOver to apply changes to running games.");
    } else {
        println!("No changes were made.");
    }

    println!();
    println!("\x1b[1m\x1b[36m===================================================\x1b[0m");
    pause();
}

fn pause() {
    print!("Press Enter to exit...");
    io::stdout().flush().unwrap();
    let mut _unused = String::new();
    let _ = io::stdin().read_line(&mut _unused);
}
