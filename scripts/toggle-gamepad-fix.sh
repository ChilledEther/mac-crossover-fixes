#!/usr/bin/env zsh

# mac-crossover-fixes - Gamepad Fix Toggler for macOS Host
# Automatically toggles the windows.gaming.input DLL override for CrossOver bottles.

set -e

BOTTLES_DIR="$HOME/Library/Application Support/CrossOver/Bottles"
CROSSOVER_BIN_DIR="/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin"

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

# Print status list
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

# Prompt user for selection
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
    
    # Remove any existing windows.gaming.input line
    grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp" && mv "$user_reg.tmp" "$user_reg"
    
    echo -e "${GREEN}Successfully disabled gamepad fix for bottle: $selected_bottle${RESET}"
else
    echo -e "Enabling gamepad fix (blocking windows.gaming.input)..."
    
    # Remove any duplicate or old overrides first
    grep -v '"windows.gaming.input"' "$user_reg" > "$user_reg.tmp"
    
    # Append the override line under [Software\\Wine\\DllOverrides]
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
else
    echo "Reboot skipped. Please restart your bottle manually before running your game."
fi

echo -e "\n${BOLD}${CYAN}===================================================${RESET}"
