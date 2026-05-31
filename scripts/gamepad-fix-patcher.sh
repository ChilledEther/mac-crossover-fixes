#!/usr/bin/env zsh

# mac-crossover-fixes - Gamepad & Compatibility Fix Patcher for macOS Host
# Automatically manages Wine registry overrides and Rust GUI installations inside CrossOver bottles.

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

# Print Header
print_header() {
    echo -e "${BOLD}${CYAN}===================================================${RESET}"
    echo -e "${BOLD}${CYAN}        macOS CrossOver Fixer Patcher Tool         ${RESET}"
    echo -e "${BOLD}${CYAN}===================================================${RESET}"
    echo
}

# Check if CrossOver bottles directory exists
if [[ ! -d "$BOTTLES_DIR" ]]; then
    echo -e "${RED}Error: CrossOver bottles directory not found at:${RESET}"
    echo -e "  $BOTTLES_DIR"
    echo -e "Please make sure CrossOver is installed and has initialized at least one bottle."
    exit 1
fi

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

# Function to print status of all bottles
show_status() {
    print_header
    echo -e "${BOLD}Current Bottle Status:${RESET}"
    for i in {1..${#bottles[@]}}; do
        local bottle="${bottles[$i]}"
        local user_reg="$BOTTLES_DIR/$bottle/user.reg"
        
        # Check Gamepad status
        if grep -q '"windows.gaming.input"=""' "$user_reg"; then
            local gamepad_str="${GREEN}[ENABLED]${RESET}"
        else
            local gamepad_str="${YELLOW}[DISABLED]${RESET}"
        fi
        
        # Check DirectWrite status
        if grep -q '"dwrite"=""' "$user_reg"; then
            local dwrite_str="${GREEN}[ENABLED]${RESET}"
        else
            local dwrite_str="${YELLOW}[DISABLED]${RESET}"
        fi
        
        # Check Crash Dialog status
        if grep -q '"ShowCrashDialog"=dword:00000000' "$user_reg"; then
            local crash_str="${GREEN}[SUPPRESSED]${RESET}"
        else
            local crash_str="${YELLOW}[DEFAULT]${RESET}"
        fi
        
        # Check if Rust utility is installed
        if [[ -f "$BOTTLES_DIR/$bottle/drive_c/Utilities/crossover-fixer.exe" || -f "$BOTTLES_DIR/$bottle/drive_c/Utilities/crossover-gamepad-fixer.exe" ]]; then
            local rust_str="${GREEN}[INSTALLED]${RESET}"
        else
            local rust_str="${RED}[NOT INSTALLED]${RESET}"
        fi
        
        echo -e "  ${BOLD}$i)${RESET} ${BOLD}$bottle${RESET}"
        echo -e "     1) Unity Gamepad Support:   $gamepad_str"
        echo -e "     2) DirectWrite Text Fix:    $dwrite_str"
        echo -e "     3) Suppress Crash Dialogs:  $crash_str"
        echo -e "     GUI Utility Control Panel:  $rust_str"
    done
    echo -e "${BOLD}${CYAN}===================================================${RESET}"
}

# Function to perform Rust GUI installation
install_utility() {
    local selected_bottles=("$@")
    
    # Download release binary crossover-fixer.exe to /tmp/crossover-fixer.exe
    echo
    echo -e "${CYAN}Downloading the latest crossover-fixer.exe compiled Rust utility from GitHub Releases...${RESET}"
    local release_url="https://github.com/ChilledEther/mac-crossover-fixes/releases/download/v1.0.2/crossover-fixer.exe"
    local tmp_bin="/tmp/crossover-fixer.exe"
    
    if curl -L -o "$tmp_bin" "$release_url"; then
        echo -e "${GREEN}Download successful.${RESET}"
    else
        echo -e "${RED}Error: Failed to download the Rust utility from GitHub Releases.${RESET}"
        exit 1
    fi

    # Perform installation in chosen bottles
    for bottle in "${selected_bottles[@]}"; do
        echo
        echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
        echo -e "${BOLD}Installing Rust GUI Control Panel in bottle: ${YELLOW}$bottle${RESET}"
        echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
        
        local drive_c="$BOTTLES_DIR/$bottle/drive_c"
        local utilities_dir="$drive_c/Utilities"
        
        # Ensure C:\Utilities folder exists
        mkdir -p "$utilities_dir"
        
        # 1. Copy crossover-fixer.exe to C:\Utilities\
        cp "$tmp_bin" "$utilities_dir/crossover-fixer.exe"
        
        # 2. Write and execute shortcut generator on-the-fly inside the bottle C: drive
        echo "Creating Start Menu shortcut pointing to CrossOver Fixer..."
        local shortcut_name="CrossOver Fixer"
        cat << 'EOF' > "$drive_c/CreateShortcut.vbs"
Set args = WScript.Arguments
If args.Count < 2 Then
    WScript.Quit 1
End If
Dim shortcutName, targetPath, iconPath
shortcutName = Replace(args(0), Chr(0), "")
targetPath = Replace(args(1), Chr(0), "")
Set Shell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Dim appData, startMenuPath
appData = Replace(Shell.ExpandEnvironmentStrings("%APPDATA%"), Chr(0), "")
startMenuPath = appData & "\Microsoft\Windows\Start Menu\Programs"
If Not FSO.FolderExists(startMenuPath) Then
    startMenuPath = appData & "\Microsoft\Windows\Start Menu"
End If
Dim lnkPath
lnkPath = startMenuPath & "\" & shortcutName & ".lnk"
Set Link = Shell.CreateShortcut(lnkPath)
Link.TargetPath = targetPath
Link.WorkingDirectory = Replace(FSO.GetParentFolderName(targetPath), Chr(0), "")
Link.Description = "Toggle CrossOver Gamepad & Registry Fixes"
If args.Count >= 3 Then
    iconPath = Replace(args(2), Chr(0), "")
End If
If iconPath <> "" Then
    Link.IconLocation = iconPath
End If
Link.Save
EOF

        if [[ -x "$CROSSOVER_BIN_DIR/wine" ]]; then
            "$CROSSOVER_BIN_DIR/wine" --bottle "$bottle" cscript "C:\\CreateShortcut.vbs" "$shortcut_name" "C:\\Utilities\\crossover-fixer.exe" "C:\\Utilities\\crossover-fixer.exe,0" >/dev/null 2>&1
        else
            echo -e "${RED}Error: wine command not found. Cannot register shortcut.${RESET}"
        fi
        rm -f "$drive_c/CreateShortcut.vbs"

        # 3. Synchronize and export menus natively to extract icon and generate macOS wrapper .app
        if [[ -x "$CROSSOVER_BIN_DIR/cxmenu" ]]; then
            echo "Synchronizing CrossOver menus to extract and register embedded icon..."
            "$CROSSOVER_BIN_DIR/cxmenu" --sync --bottle "$bottle" >/dev/null 2>&1
            "$CROSSOVER_BIN_DIR/cxmenu" --bottle "$bottle" --install >/dev/null 2>&1
        fi

        echo -e "${GREEN}Rust GUI Control Panel successfully installed inside bottle: $bottle${RESET}"
    done

    # Clean up downloaded tmp binary
    rm -f "$tmp_bin"

    echo
    echo -e "${BOLD}${GREEN}===================================================${RESET}"
    echo -e "${BOLD}${GREEN}   RUST GUI CONTROL PANEL INSTALLATION COMPLETE    ${RESET}"
    echo -e "${BOLD}${GREEN}===================================================${RESET}"
}

# Function to perform uninstallation
uninstall_utility() {
    local selected_bottles=("$@")
    
    for bottle in "${selected_bottles[@]}"; do
        echo
        echo -e "${BOLD}${RED}---------------------------------------------------${RESET}"
        echo -e "${BOLD}Uninstalling fixer and utility from bottle: ${YELLOW}$bottle${RESET}"
        echo -e "${BOLD}${RED}---------------------------------------------------${RESET}"
        
        local drive_c="$BOTTLES_DIR/$bottle/drive_c"
        local user_reg="$BOTTLES_DIR/$bottle/user.reg"
        
        # 1. Restore registry DLL overrides to default
        if [[ -f "$user_reg" ]]; then
            echo "Restoring default registry DLL overrides..."
            grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" || true
            grep -v '"dwrite"' "$user_reg.tmp" > "$user_reg.tmp2" || true
            grep -v '"ShowCrashDialog"' "$user_reg.tmp2" > "$user_reg"
            rm -f "$user_reg.tmp" "$user_reg.tmp2"
        fi
        
        # 2. Delete Rust binary
        echo "Removing Rust binary..."
        rm -f "$drive_c/Utilities/crossover-gamepad-fixer.exe"
        rm -f "$drive_c/Utilities/crossover-fixer.exe"
        rm -f "$drive_c/Games/crossover-gamepad-fixer.exe"
        rm -f "$drive_c/Games/crossover-fixer.exe"
        
        # 3. Delete Start Menu `.lnk` files
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Gamepad Fixer.lnk"
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Gamepad Fixer.lnk"
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/CrossOver Fixer.lnk"
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/CrossOver Fixer.lnk"
        
        # 4. Synchronize menus to drop launcher
        if [[ -x "$CROSSOVER_BIN_DIR/cxmenu" ]]; then
            echo "Synchronizing CrossOver menus..."
            "$CROSSOVER_BIN_DIR/cxmenu" --sync --bottle "$bottle"
        fi
        
        # 5. Delete native macOS wrapper .app bundles
        local app_path="$HOME/Applications/CrossOver/Gamepad Fixer.app"
        if [[ -d "$app_path" ]]; then
            echo "Deleting macOS Gamepad Fixer app wrapper bundle..."
            rm -rf "$app_path"
        fi
        local generic_app_path="$HOME/Applications/CrossOver/CrossOver Fixer.app"
        if [[ -d "$generic_app_path" ]]; then
            echo "Deleting macOS CrossOver Fixer app wrapper bundle..."
            rm -rf "$generic_app_path"
        fi
        local legacy_app_path="$HOME/Applications/CrossOver/Toggle Gamepad Fix ($bottle).app"
        if [[ -d "$legacy_app_path" ]]; then
            echo "Deleting legacy macOS app wrapper bundle..."
            rm -rf "$legacy_app_path"
        fi
        
        echo -e "${GREEN}Successfully uninstalled and cleaned bottle: $bottle${RESET}"
    done
    
    echo
    echo -e "${BOLD}${GREEN}===================================================${RESET}"
    echo -e "${BOLD}${GREEN}   UNINSTALLATION PROCESS COMPLETE                 ${RESET}"
    echo -e "${BOLD}${GREEN}===================================================${RESET}"
    echo -e "\nPlease quit and relaunch **CrossOver** to apply visual changes."
}

# ----------------------------------------------------
# Parse CLI Options
# ----------------------------------------------------
ACTION=""
BOTTLE_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status)
            ACTION="status"
            shift
            ;;
        --install)
            ACTION="install"
            shift
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                BOTTLE_ARG="$1"
                shift
            fi
            ;;
        --uninstall)
            ACTION="uninstall"
            shift
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                BOTTLE_ARG="$1"
                shift
            fi
            ;;
        --help|-h)
            print_header
            echo "Usage: gamepad-fix-patcher.sh [FLAGS]"
            echo
            echo "Flags:"
            echo "  --status             Show the status of all bottles"
            echo "  --install [BOTTLE]   Install the Rust GUI utility in the specified bottle or 'all'"
            echo "  --uninstall [BOTTLE] Uninstall the Rust GUI utility in the specified bottle or 'all'"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            exit 1
            ;;
    esac
done

# Run actions based on flags
if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$ACTION" == "install" ]]; then
    target_bottles=()
    if [[ "$BOTTLE_ARG" == "all" || "$BOTTLE_ARG" == "ALL" ]]; then
        target_bottles=("${bottles[@]}")
    elif [[ -n "$BOTTLE_ARG" ]]; then
        # Check if specified bottle exists
        found=false
        for b in "${bottles[@]}"; do
            if [[ "$b" == "$BOTTLE_ARG" ]]; then
                target_bottles+=("$b")
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            echo -e "${RED}Error: Bottle '$BOTTLE_ARG' not found.${RESET}"
            exit 1
        fi
    else
        # Prompt interactively
        show_status
        echo -ne "Select bottle(s) to install the Rust GUI Utility (e.g. 1, 2 or 'all' or 'q'): "
        read -r selection_input
        if [[ "$selection_input" == "q" || "$selection_input" == "Q" ]]; then
            exit 0
        fi
        if [[ "$selection_input" == "all" ]]; then
            target_bottles=("${bottles[@]}")
        else
            IFS=',' read -rA raw_choices <<< "$selection_input"
            for choice in "${raw_choices[@]}"; do
                choice=$(echo "$choice" | xargs)
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#bottles[@]} )); then
                    target_bottles+=("${bottles[$choice]}")
                fi
            done
        fi
    fi
    
    if [[ ${#target_bottles[@]} -eq 0 ]]; then
        echo -e "${RED}No bottles selected.${RESET}"
        exit 1
    fi
    install_utility "${target_bottles[@]}"
    exit 0
fi

if [[ "$ACTION" == "uninstall" ]]; then
    target_bottles=()
    if [[ "$BOTTLE_ARG" == "all" || "$BOTTLE_ARG" == "ALL" ]]; then
        target_bottles=("${bottles[@]}")
    elif [[ -n "$BOTTLE_ARG" ]]; then
        # Check if specified bottle exists
        found=false
        for b in "${bottles[@]}"; do
            if [[ "$b" == "$BOTTLE_ARG" ]]; then
                target_bottles+=("$b")
                found=true
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            echo -e "${RED}Error: Bottle '$BOTTLE_ARG' not found.${RESET}"
            exit 1
        fi
    else
        # Prompt interactively
        show_status
        echo -ne "Select bottle(s) to uninstall from (e.g. 1, 2 or 'all' or 'q'): "
        read -r selection_input
        if [[ "$selection_input" == "q" || "$selection_input" == "Q" ]]; then
            exit 0
        fi
        if [[ "$selection_input" == "all" ]]; then
            target_bottles=("${bottles[@]}")
        else
            IFS=',' read -rA raw_choices <<< "$selection_input"
            for choice in "${raw_choices[@]}"; do
                choice=$(echo "$choice" | xargs)
                if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#bottles[@]} )); then
                    target_bottles+=("${bottles[$choice]}")
                fi
            done
        fi
    fi
    
    if [[ ${#target_bottles[@]} -eq 0 ]]; then
        echo -e "${RED}No bottles selected.${RESET}"
        exit 1
    fi
    uninstall_utility "${target_bottles[@]}"
    exit 0
fi

# ----------------------------------------------------
# DEFAULT: FALLBACK INTERACTIVE MODE (No flags passed)
# ----------------------------------------------------
print_header
echo -e "${BOLD}Select an action:${RESET}"
echo -e "  ${BOLD}1)${RESET} Toggle Registry Patches in a Bottle (macOS Host CLI)"
echo -e "  ${BOLD}2)${RESET} Install Rust GUI Control Panel inside Bottles (Runs in CrossOver GUI)"
echo -e "  ${BOLD}3)${RESET} Uninstall Fixes & Utility from Bottles (Restore default settings)"
echo -e "  ${BOLD}q)${RESET} Quit"
echo
echo -ne "Choice (1-3 or 'q'): "
read -r main_choice

if [[ "$main_choice" == "q" || "$main_choice" == "Q" ]]; then
    echo "Exiting..."
    exit 0
fi

if [[ "$main_choice" == "1" ]]; then
    # Toggle registry fixes
    echo
    echo -e "${BOLD}Detected CrossOver Bottles:${RESET}"
    for i in {1..${#bottles[@]}}; do
        bottle="${bottles[$i]}"
        echo -e "  ${BOLD}$i)${RESET} $bottle"
    done
    echo
    echo -ne "Select a bottle to manage (1-${#bottles[@]}) or 'q' to quit: "
    read -r choice
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        exit 0
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#bottles[@]} )); then
        selected_bottle="${bottles[$choice]}"
        user_reg="$BOTTLES_DIR/$selected_bottle/user.reg"
        
        while true; do
            echo
            echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
            echo -e "${BOLD}Compatibility Patches for Bottle: ${YELLOW}$selected_bottle${RESET}"
            echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
            
            if grep -q '"windows.gaming.input"=""' "$user_reg" 2>/dev/null; then
                local gamepad_status="${GREEN}[ENABLED]${RESET}"
            else
                local gamepad_status="${YELLOW}[DISABLED]${RESET}"
            fi
            
            if grep -q '"dwrite"=""' "$user_reg" 2>/dev/null; then
                local dwrite_status="${GREEN}[ENABLED]${RESET}"
            else
                local dwrite_status="${YELLOW}[DISABLED]${RESET}"
            fi
            
            if grep -q '"ShowCrashDialog"=dword:00000000' "$user_reg" 2>/dev/null; then
                local crash_status="${GREEN}[SUPPRESSED]${RESET}"
            else
                local crash_status="${YELLOW}[DEFAULT]${RESET}"
            fi
            
            echo -e "  ${BOLD}1)${RESET} Unity Gamepad Support:   $gamepad_status"
            echo -e "  ${BOLD}2)${RESET} DirectWrite Text Fix:    $dwrite_status"
            echo -e "  ${BOLD}3)${RESET} Suppress Crash Dialogs:  $crash_status"
            echo -e "  ${BOLD}b)${RESET} Back to Main Menu"
            echo
            echo -ne "Select patch to toggle (1-3 or 'b'): "
            read -r patch_choice
            
            if [[ "$patch_choice" == "b" || "$patch_choice" == "B" ]]; then
                break
            fi
            
            if [[ "$patch_choice" == "1" ]]; then
                if [[ "$gamepad_status" == "${GREEN}[ENABLED]${RESET}" ]]; then
                    echo "Disabling gamepad fix..."
                    grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" && mv "$user_reg.tmp" "$user_reg"
                else
                    echo "Enabling gamepad fix..."
                    grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" || true
                    awk '/\[Software\\\\Wine\\\\DllOverrides\]/ { print; print "\"windows.gaming.input\"=\"\""; next }1' "$user_reg.tmp" > "$user_reg"
                fi
                echo -e "${GREEN}Gamepad fix updated successfully.${RESET}"
            elif [[ "$patch_choice" == "2" ]]; then
                if [[ "$dwrite_status" == "${GREEN}[ENABLED]${RESET}" ]]; then
                    echo "Disabling DirectWrite fix..."
                    grep -v '"dwrite"' "$user_reg" > "$user_reg.tmp" && mv "$user_reg.tmp" "$user_reg"
                else
                    echo "Enabling DirectWrite fix..."
                    grep -v '"dwrite"' "$user_reg" > "$user_reg.tmp" || true
                    awk '/\[Software\\\\Wine\\\\DllOverrides\]/ { print; print "\"dwrite\"=\"\""; next }1' "$user_reg.tmp" > "$user_reg"
                fi
                echo -e "${GREEN}DirectWrite fix updated successfully.${RESET}"
            elif [[ "$patch_choice" == "3" ]]; then
                if [[ "$crash_status" == "${GREEN}[SUPPRESSED]${RESET}" ]]; then
                    echo "Restoring default crash dialog behavior..."
                    grep -v '"ShowCrashDialog"' "$user_reg" > "$user_reg.tmp" || true
                    if grep -q '\[Software\\\\Wine\\\\WineDbg\]' "$user_reg.tmp"; then
                        awk '/\[Software\\\\Wine\\\\WineDbg\]/ { print; print "\"ShowCrashDialog\"=dword:00000001"; next }1' "$user_reg.tmp" > "$user_reg"
                    else
                        cat "$user_reg.tmp" <(echo -e "\n[Software\\\\Wine\\\\WineDbg]\n\"ShowCrashDialog\"=dword:00000001") > "$user_reg"
                    fi
                else
                    echo "Suppressing Wine crash dialogs..."
                    grep -v '"ShowCrashDialog"' "$user_reg" > "$user_reg.tmp" || true
                    if grep -q '\[Software\\\\Wine\\\\WineDbg\]' "$user_reg.tmp"; then
                        awk '/\[Software\\\\Wine\\\\WineDbg\]/ { print; print "\"ShowCrashDialog\"=dword:00000000"; next }1' "$user_reg.tmp" > "$user_reg"
                    else
                        cat "$user_reg.tmp" <(echo -e "\n[Software\\\\Wine\\\\WineDbg]\n\"ShowCrashDialog\"=dword:00000000") > "$user_reg"
                    fi
                fi
                echo -e "${GREEN}Crash dialog status updated successfully.${RESET}"
            fi
            rm -f "$user_reg.tmp"
        done
        
        echo -ne "\nWould you like to simulate a Windows reboot for '$selected_bottle' now? (y/n): "
        read -r reboot_choice
        if [[ "$reboot_choice" == "y" && -x "$CROSSOVER_BIN_DIR/cxreboot" ]]; then
            "$CROSSOVER_BIN_DIR/cxreboot" --bottle "$selected_bottle"
        fi
    fi
elif [[ "$main_choice" == "2" ]]; then
    # Interactive install
    install_utility
elif [[ "$main_choice" == "3" ]]; then
    # Interactive uninstall
    uninstall_utility
else
    echo -e "${RED}Invalid selection.${RESET}"
    exit 1
fi

echo -e "\n${BOLD}${CYAN}===================================================${RESET}"
