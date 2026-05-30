#!/usr/bin/env zsh

# mac-crossover-fixes - Gamepad Fix Patcher for macOS Host
# Automatically manages the windows.gaming.input DLL override and Rust GUI installations inside CrossOver bottles.

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
    echo -e "${BOLD}${CYAN}        CrossOver Gamepad Fix Patcher (macOS)      ${RESET}"
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

# Function to print status of all bottles
show_status() {
    print_header
    echo -e "${BOLD}Current Bottle Status:${RESET}"
    for i in {1..${#bottles[@]}}; do
        local bottle="${bottles[$i]}"
        local reg_status=$(get_patch_status "$bottle")
        
        if [[ "$reg_status" == "ENABLED" ]]; then
            local reg_str="${GREEN}[ENABLED] (Bypassing windows.gaming.input)${RESET}"
        else
            local reg_str="${YELLOW}[DISABLED] (Default behavior)${RESET}"
        fi
        
        # Check if Rust utility is installed
        if [[ -f "$BOTTLES_DIR/$bottle/drive_c/Utilities/crossover-gamepad-fixer.exe" ]]; then
            local rust_str="${GREEN}[INSTALLED]${RESET}"
        else
            local rust_str="${RED}[NOT INSTALLED]${RESET}"
        fi
        
        echo -e "  ${BOLD}$i)${RESET} ${BOLD}$bottle${RESET}"
        echo -e "     Registry Fix: $reg_str"
        echo -e "     Rust GUI Utility: $rust_str"
    done
    echo -e "${BOLD}${CYAN}===================================================${RESET}"
}

# Function to perform Rust GUI installation
install_utility() {
    local selected_bottles=("$@")
    
    # Download release binary crossover-gamepad-fixer.exe to /tmp/crossover-gamepad-fixer.exe
    echo
    echo -e "${CYAN}Downloading the latest crossover-gamepad-fixer.exe compiled Rust utility from GitHub Releases...${RESET}"
    local release_url="https://github.com/ChilledEther/mac-crossover-fixes/releases/download/v1.0.1/crossover-gamepad-fixer.exe"
    local tmp_bin="/tmp/crossover-gamepad-fixer.exe"
    
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
        echo -e "${BOLD}Installing Rust GUI Utility inside bottle: ${YELLOW}$bottle${RESET}"
        echo -e "${BOLD}${CYAN}---------------------------------------------------${RESET}"
        
        local drive_c="$BOTTLES_DIR/$bottle/drive_c"
        local utilities_dir="$drive_c/Utilities"
        
        # Ensure C:\Utilities folder exists
        mkdir -p "$utilities_dir"
        
        # 1. Copy crossover-gamepad-fixer.exe to C:\Utilities\
        cp "$tmp_bin" "$utilities_dir/crossover-gamepad-fixer.exe"
        
        # 2. Create native shortcut launcher via CrossOver's cxmenu tool
        echo "Creating Start Menu shortcut pointing to crossover-gamepad-fixer.exe..."
        local shortcut_name="Toggle Gamepad Fix ($bottle)"
        if [[ -x "$CROSSOVER_BIN_DIR/cxmenu" ]]; then
            # Create the menu entry
            "$CROSSOVER_BIN_DIR/cxmenu" --bottle "$bottle" --create "StartMenu/Programs/$shortcut_name" --command "C:\\Utilities\\crossover-gamepad-fixer.exe" --description "Toggle CrossOver Gamepad Fix" --type "windows" >/dev/null 2>&1
            # Synchronize and install menus to extract icon and register launcher
            echo "Synchronizing CrossOver menus to extract and register embedded icon..."
            "$CROSSOVER_BIN_DIR/cxmenu" --sync --bottle "$bottle"
            "$CROSSOVER_BIN_DIR/cxmenu" --bottle "$bottle" --install >/dev/null 2>&1
        else
            echo -e "${RED}Error: cxmenu command not found. Cannot register shortcut.${RESET}"
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
}

# Function to perform uninstallation
uninstall_utility() {
    local selected_bottles=("$@")
    
    for bottle in "${selected_bottles[@]}"; do
        echo
        echo -e "${BOLD}${RED}---------------------------------------------------${RESET}"
        echo -e "${BOLD}Uninstalling fix and utility from bottle: ${YELLOW}$bottle${RESET}"
        echo -e "${BOLD}${RED}---------------------------------------------------${RESET}"
        
        local drive_c="$BOTTLES_DIR/$bottle/drive_c"
        local user_reg="$BOTTLES_DIR/$bottle/user.reg"
        
        # 1. Restore registry DLL override to default
        if [[ -f "$user_reg" ]]; then
            echo "Restoring default registry DLL behavior..."
            grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" && mv "$user_reg.tmp" "$user_reg"
        fi
        
        # 2. Delete Rust binary
        echo "Removing Rust binary..."
        rm -f "$drive_c/Utilities/crossover-gamepad-fixer.exe"
        rm -f "$drive_c/Games/crossover-gamepad-fixer.exe"
        
        # 3. Delete Start Menu `.lnk` files
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Toggle Gamepad Fix ($bottle).lnk"
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Toggle Gamepad Fix ($bottle).lnk"
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Toggle Gamepad Fix.lnk"
        rm -f "$drive_c/users/crossover/AppData/Roaming/Microsoft/Windows/Start Menu/Toggle Gamepad Fix.lnk"
        
        # 4. Synchronize menus to drop launcher
        if [[ -x "$CROSSOVER_BIN_DIR/cxmenu" ]]; then
            echo "Synchronizing CrossOver menus..."
            "$CROSSOVER_BIN_DIR/cxmenu" --sync --bottle "$bottle"
        fi
        
        # 5. Delete native macOS wrapper .app bundles
        local app_path="$HOME/Applications/CrossOver/Toggle Gamepad Fix ($bottle).app"
        if [[ -d "$app_path" ]]; then
            echo "Deleting macOS app wrapper bundle..."
            rm -rf "$app_path"
        fi
        local generic_app_path="$HOME/Applications/CrossOver/Toggle Gamepad Fix.app"
        if [[ -d "$generic_app_path" ]]; then
            echo "Deleting generic macOS app wrapper bundle..."
            rm -rf "$generic_app_path"
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
echo -e "  ${BOLD}1)${RESET} Toggle Registry Patch in a Bottle (macOS Host CLI)"
echo -e "  ${BOLD}2)${RESET} Install Rust GUI Utility inside Bottles (Runs in CrossOver GUI)"
echo -e "  ${BOLD}3)${RESET} Uninstall Fix & Utility from Bottles (Restore default settings)"
echo -e "  ${BOLD}q)${RESET} Quit"
echo
echo -ne "Choice (1-3 or 'q'): "
read -r main_choice

if [[ "$main_choice" == "q" || "$main_choice" == "Q" ]]; then
    echo "Exiting..."
    exit 0
fi

if [[ "$main_choice" == "1" ]]; then
    # Toggle registry fix
    echo
    echo -e "${BOLD}Detected CrossOver Bottles:${RESET}"
    for i in {1..${#bottles[@]}}; do
        bottle="${bottles[$i]}"
        status=$(get_patch_status "$bottle")
        if [[ "$status" == "ENABLED" ]]; then
            status_str="${GREEN}[ENABLED]${RESET}"
        else
            status_str="${YELLOW}[DISABLED]${RESET}"
        fi
        echo -e "  ${BOLD}$i)${RESET} $bottle -> $status_str"
    done
    echo
    echo -ne "Select a bottle to toggle (1-${#bottles[@]}) or 'q' to quit: "
    read -r choice
    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        exit 0
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#bottles[@]} )); then
        selected_bottle="${bottles[$choice]}"
        user_reg="$BOTTLES_DIR/$selected_bottle/user.reg"
        current_status=$(get_patch_status "$selected_bottle")
        echo
        if [[ "$current_status" == "ENABLED" ]]; then
            echo -e "Disabling gamepad fix..."
            grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" && mv "$user_reg.tmp" "$user_reg"
            echo -e "${GREEN}Disabled registry override for $selected_bottle${RESET}"
        else
            echo -e "Enabling gamepad fix..."
            grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp"
            awk '/\[Software\\\\Wine\\\\DllOverrides\]/ { print; print "\"windows.gaming.input\"=\"\""; next }1' "$user_reg.tmp" > "$user_reg"
            rm -f "$user_reg.tmp"
            echo -e "${GREEN}Enabled registry override for $selected_bottle${RESET}"
        fi
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
