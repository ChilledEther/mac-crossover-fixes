#!/usr/bin/env zsh

# mac-crossover-fixes - Gamepad Fix Toggler for macOS Host
# Automatically toggles the windows.gaming.input DLL override and manages Rust GUI installations inside bottles.

set -e

BOTTLES_DIR="$HOME/Library/Application Support/CrossOver/Bottles"
CROSSOVER_BIN_DIR="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin"
SCRIPT_DIR="${0:a:h}"

# Styling utilities
BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}===================================================${RESET}"
echo -e "${BOLD}${CYAN}   CrossOver Gamepad Detection Patch Toggler (macOS)${RESET}"
echo -e "${BOLD}${CYAN}===================================================${RESET}"
echo

# Check if CrossOver bottles directory exists
if [[ ! -d "$BOTTLES_DIR" ]]; then
    echo -e "${RED}Error: CrossOver bottles directory not found at:${RESET}"
    echo -e "  $BOTTLES_DIR"
    echo -e "Please make sure CrossOver is installed and has initialized at least one bottle."
    exit 1
fi

# Function to get patch status for a bottle
get_patch_status() {
    local bottle_name="$1"
    local user_reg="$BOTTLES_DIR/$bottle_name/user.reg"
    
    if [[ ! -f "$user_reg" ]]; then
        echo "MISSING"
        return
    fi
    
    if grep -q '"windows.gaming.input"=""' "$user_reg"; then
        echo "ENABLED"
    else
        echo "DISABLED"
    fi
}

# Find all bottles
cd "$BOTTLES_DIR"
bottles=()
for dir in *; do
    if [[ -d "$dir" && -f "$dir/user.reg" ]]; then
        bottles+=("$dir")
    fi
done

if [[ ${#bottles[@]} -eq 0 ]]; then
    echo -e "${RED}Error: No active CrossOver bottles found.${RESET}"
    exit 1
fi

# Print Main Menu
echo -e "${BOLD}Select an action:${RESET}"
echo -e "  ${BOLD}1)${RESET} Toggle Registry Patch in a Bottle (macOS Host CLI)"
echo -e "  ${BOLD}2)${RESET} Install Rust GUI Utility inside Bottles (Runs in CrossOver GUI)"
echo -e "  ${BOLD}q)${RESET} Quit"
echo
echo -ne "Choice (1-2 or 'q'): "
read -r main_choice

if [[ "$main_choice" == "q" || "$main_choice" == "Q" ]]; then
    echo "Exiting..."
    exit 0
fi

if [[ "$main_choice" != "1" && "$main_choice" != "2" ]]; then
    echo -e "${RED}Invalid selection. Exiting...${RESET}"
    exit 1
fi

# Print bottle list
echo
echo -e "${BOLD}Detected CrossOver Bottles:${RESET}"
for i in {1..${#bottles[@]}}; do
    bottle="${bottles[$i]}"
    status=$(get_patch_status "$bottle")
    
    if [[ "$status" == "ENABLED" ]]; then
        status_str="${GREEN}[ENABLED] (Fix Active - Gamepad input bypassed to XInput)${RESET}"
    elif [[ "$status" == "DISABLED" ]]; then
        status_str="${YELLOW}[DISABLED] (Default - Using windows.gaming.input)${RESET}"
    else
        status_str="${RED}[UNKNOWN] (Registry missing or corrupt)${RESET}"
    fi
    
    echo -e "  ${BOLD}$i)${RESET} $bottle -> $status_str"
done
echo

# ----------------------------------------------------
# ACTION 1: Toggle Registry Patch
# ----------------------------------------------------
if [[ "$main_choice" == "1" ]]; then
    echo -ne "Select a bottle to toggle (1-${#bottles[@]}) or 'q' to quit: "
    read -r choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        echo "Exiting..."
        exit 0
    fi

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#bottles[@]} )); then
        echo -e "${RED}Invalid selection. Exiting...${RESET}"
        exit 1
    fi

    selected_bottle="${bottles[$choice]}"
    user_reg="$BOTTLES_DIR/$selected_bottle/user.reg"
    current_status=$(get_patch_status "$selected_bottle")

    echo
    echo -e "Selected Bottle: ${BOLD}$selected_bottle${RESET}"

    if [[ "$current_status" == "ENABLED" ]]; then
        echo -e "Disabling gamepad fix (restoring default behavior)..."
        grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" && mv "$user_reg.tmp" "$user_reg"
        echo -e "${GREEN}Successfully disabled gamepad fix for bottle: $selected_bottle${RESET}"
    else
        echo -e "Enabling gamepad fix (blocking windows.gaming.input)..."
        grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp"
        awk '/\[Software\\\\Wine\\\\DllOverrides\]/ { print; print "\"windows.gaming.input\"=\"\""; next }1' "$user_reg.tmp" > "$user_reg"
        rm -f "$user_reg.tmp"
        echo -e "${GREEN}Successfully enabled gamepad fix for bottle: $selected_bottle${RESET}"
    fi

    # Ask if they want to reboot the bottle
    echo
    echo -ne "Would you like to simulate a Windows reboot for '$selected_bottle' to apply changes? (y/n): "
    read -r reboot_choice

    if [[ "$reboot_choice" == "y" || "$reboot_choice" == "Y" ]]; then
        if [[ -x "$CROSSOVER_BIN_DIR/cxreboot" ]]; then
            echo "Rebooting bottle '$selected_bottle'..."
            "$CROSSOVER_BIN_DIR/cxreboot" --bottle "$selected_bottle"
            echo -e "${GREEN}Reboot complete.${RESET}"
        else
            echo -e "${YELLOW}Warning: cxreboot command not found at $CROSSOVER_BIN_DIR/cxreboot.${RESET}"
            echo "Please restart CrossOver manually to apply changes."
        fi
    fi
fi

# ----------------------------------------------------
# ACTION 2: Install Rust GUI Utility
# ----------------------------------------------------
if [[ "$main_choice" == "2" ]]; then
    echo -ne "Select bottle(s) to install the Rust GUI Utility (e.g. 1, 2 or 'all' or 'q'): "
    read -r selection_input

    if [[ "$selection_input" == "q" || "$selection_input" == "Q" ]]; then
        echo "Exiting..."
        exit 0
    fi

    selected_indices=()
    if [[ "$selection_input" == "all" || "$selection_input" == "ALL" ]]; then
        for i in {1..${#bottles[@]}}; do
            selected_indices+=($i)
        done
    else
        # Split selection input by comma
        IFS=',' read -rA raw_choices <<< "$selection_input"
        for choice in "${raw_choices[@]}"; do
            choice=$(echo "$choice" | xargs) # trim whitespace
            if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#bottles[@]} )); then
                selected_indices+=($choice)
            else
                echo -e "${RED}Warning: Ignoring invalid selection '$choice'${RESET}"
            fi
        done
    fi

    if [[ ${#selected_indices[@]} -eq 0 ]]; then
        echo -e "${RED}No valid bottles selected. Exiting...${RESET}"
        exit 1
    fi

    # Download release binary crossover-gamepad-fixer.exe to /tmp/crossover-gamepad-fixer.exe
    echo
    echo -e "${CYAN}Downloading the latest crossover-gamepad-fixer.exe compiled Rust utility from GitHub Releases...${RESET}"
    release_url="https://github.com/ChilledEther/mac-crossover-fixes/releases/download/v1.0.0/crossover-gamepad-fixer.exe"
    tmp_bin="/tmp/crossover-gamepad-fixer.exe"
    
    if curl -L -o "$tmp_bin" "$release_url"; then
        echo -e "${GREEN}Download successful.${RESET}"
    else
        echo -e "${RED}Error: Failed to download the Rust utility from GitHub Releases.${RESET}"
        exit 1
    fi

    # Perform installation in chosen bottles
    for idx in "${selected_indices[@]}"; do
        bottle="${bottles[$idx]}"
        echo
        echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
        echo -e "${BOLD}Installing Rust GUI Utility inside bottle: ${YELLOW}$bottle${RESET}"
        echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
        
        drive_c="$BOTTLES_DIR/$bottle/drive_c"
        games_dir="$drive_c/Games"
        
        # Ensure C:\Games folder exists
        mkdir -p "$games_dir"
        
        # 1. Copy crossover-gamepad-fixer.exe and GamepadFix.ico to C:\Games\
        cp "$tmp_bin" "$games_dir/crossover-gamepad-fixer.exe"
        if [[ -f "$SCRIPT_DIR/GamepadFix.ico" ]]; then
            cp "$SCRIPT_DIR/GamepadFix.ico" "$games_dir/GamepadFix.ico"
        fi
        
        # 2. Copy CreateShortcut.vbs to drive_c/ and run via Wine to build shortcut
        if [[ -f "$SCRIPT_DIR/CreateShortcut.vbs" ]]; then
            cp "$SCRIPT_DIR/CreateShortcut.vbs" "$drive_c/CreateShortcut.vbs"
            echo "Creating Start Menu shortcut pointing to crossover-gamepad-fixer.exe..."
            
            if [[ -x "$CROSSOVER_BIN_DIR/wine" ]]; then
                "$CROSSOVER_BIN_DIR/wine" --bottle "$bottle" cscript "C:\\CreateShortcut.vbs" "Toggle Gamepad Fix" "C:\\Games\\crossover-gamepad-fixer.exe"
            else
                echo -e "${RED}Error: wine command not found. Cannot register shortcut.${RESET}"
            fi
            rm -f "$drive_c/CreateShortcut.vbs"
        fi

        # 3. Synchronize menus
        if [[ -x "$CROSSOVER_BIN_DIR/cxmenu" ]]; then
            echo "Synchronizing CrossOver menus..."
            "$CROSSOVER_BIN_DIR/cxmenu" --sync --bottle "$bottle"
        fi

        # 4. Generate multi-resolution PNG icons inside bottle's hicolor folder
        local png_src="$SCRIPT_DIR/gamepad_fix_icon.png"
        if [[ -f "$png_src" ]]; then
            echo "Generating GUI hicolor PNG icons..."
            local sizes=(16 24 32 48 64 96 128 192 256)
            for size in "${sizes[@]}"; do
                local size_dir="$BOTTLES_DIR/$bottle/windata/cxmenu/icons/hicolor/${size}x${size}/apps"
                mkdir -p "$size_dir"
                sips -s format png -z "$size" "$size" "$png_src" --out "$size_dir/Toggle_Gamepad_Fix.png" >/dev/null 2>&1
            done
        fi

        # 5. Patch cxmenu_macosx.plist using inline Python
        local plist_path="$BOTTLES_DIR/$bottle/desktopdata/cxmenu/cxmenu_macosx.plist"
        if [[ -f "$plist_path" ]]; then
            echo "Patching GUI database plist..."
            python3 -c "
import plistlib, os
plist_path = '$plist_path'
bottle_path = '$BOTTLES_DIR/$bottle'
try:
    with open(plist_path, 'rb') as f:
        data = plistlib.load(f)
    updated = False
    for top_key in data:
        children = data[top_key].get('Children', {})
        start_menu = children.get('StartMenu/', {}).get('Children', {})
        win_apps = start_menu.get('Windows Applications/', {}).get('Children', {})
        if 'Toggle Gamepad Fix' in win_apps:
            target_icon = os.path.join(bottle_path, 'windata', 'cxmenu', 'icons', 'hicolor', '256x256', 'apps', 'Toggle_Gamepad_Fix.png')
            win_apps['Toggle Gamepad Fix']['Icon'] = target_icon
            win_apps['Toggle Gamepad Fix']['RobustIcon'] = '%WINEPREFIX%/windata/cxmenu/icons/hicolor/256x256/apps/Toggle_Gamepad_Fix.png'
            updated = True
    if updated:
        with open(plist_path, 'wb') as f:
            plistlib.dump(data, f)
        print('  Successfully mapped custom icon to CrossOver GUI.')
except Exception as e:
    print('  Error patching plist:', e)
"
        fi

        # 6. Override helper .app bundle icon
        local app_path="$HOME/Applications/CrossOver/Toggle Gamepad Fix ($bottle).app"
        local icns_src="$SCRIPT_DIR/CrossOverHelper.icns"
        if [[ -d "$app_path" && -f "$icns_src" ]]; then
            echo "Updating native macOS app launcher icon..."
            cp "$icns_src" "$app_path/Contents/Resources/CrossOverHelper.icns"
            touch "$app_path"
        fi

        echo -e "${GREEN}Rust GUI Utility successfully installed inside bottle: $bottle${RESET}"
    done

    # Clean up downloaded tmp binary
    rm -f "$tmp_bin"

    echo
    echo -e "${BOLD}${GREEN}===================================================${RESET}"
    echo -e "${BOLD}${GREEN}   RUST GUI UTILITY INSTALLATION PROCESS COMPLETE  ${RESET}"
    echo -e "${BOLD}${GREEN}===================================================${RESET}"
    echo -e "\nPlease quit (Cmd + Q) and relaunch **CrossOver** to refresh the program icons."
fi

echo -e "\n${BOLD}${CYAN}===================================================${RESET}"
