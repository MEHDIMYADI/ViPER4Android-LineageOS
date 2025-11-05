#!/system/bin/sh
# action.sh

APP_PACKAGE="com.wstxda.viper4android"
APP_ACTIVITY="com.wstxda.viper4android.MainActivity"
DOWNLOAD_URL="https://github.com/WSTxda/ViperFX-RE-Releases/releases/latest"
MODULE_ID="ViPER4Android-LineageOS"
LIB_PATH="/system/vendor/lib/soundfx/libv4a_re.so"

# Log function
log_message() {
    echo "[INFO] $1"
}

error_message() {
    echo "[ERROR] $1"
}

check_driver_installation() {
    log_message "Checking driver installation..."
    
    # Check if library files exist
    if [ -f "$LIB_PATH" ] || [ -f "/system/lib/soundfx/libv4a_re.so" ]; then
        log_message "✓ Driver libraries installed successfully"
        return 0
    else
        error_message "✗ Driver libraries not found"
        return 1
    fi
}

check_xml_patching() {
    log_message "Checking audio effects configuration..."
    
    local config_found=false
    local patch_found=false
    
    # Check all audio effects configuration files
    for config_file in /odm/etc/audio_effects.xml /vendor/etc/audio_effects.xml /system/etc/audio_effects.xml /system/vendor/etc/audio_effects.xml; do
        if [ -f "$config_file" ]; then
            config_found=true
            log_message "Found config: $config_file"
            
            # Check if V4A library is referenced
            if grep -q "v4a_re" "$config_file"; then
                log_message "✓ V4A library found in $config_file"
                patch_found=true
            fi
            
            # Check if V4A effect is referenced
            if grep -q "v4a_standard_re" "$config_file"; then
                log_message "✓ V4A effect found in $config_file"
                patch_found=true
            fi
        fi
    done
    
    if ! $config_found; then
        error_message "No audio effects configuration files found"
        return 1
    fi
    
    if $patch_found; then
        log_message "✓ Audio effects configuration patched successfully"
        return 0
    else
        error_message "✗ V4A patches not found in configuration files"
        return 1
    fi
}

check_module_status() {
    log_message "Checking module status..."
    
    # Check if module is active in Magisk
    if [ -d "/data/adb/modules/$MODULE_ID" ]; then
        log_message "✓ Module directory exists"
        
        # Check if module is enabled
        if [ -f "/data/adb/modules/$MODULE_ID/disable" ]; then
            error_message "✗ Module is disabled"
            return 1
        else
            log_message "✓ Module is enabled"
            return 0
        fi
    else
        error_message "✗ Module directory not found"
        return 1
    fi
}

check_sepolicy_status() {
    log_message "Checking SELinux policies..."
    
    # Check if SELinux policies are applied
    if dmesg | grep -q "avc.*denied.*v4a"; then
        error_message "✗ SELinux denials detected for V4A"
        return 1
    else
        log_message "✓ No SELinux denials detected"
        return 0
    fi
}

check_app_installation() {
    log_message "Checking application installation..."
    
    if pm list packages | grep -q "$APP_PACKAGE"; then
        log_message "✓ ViPER4Android app installed"
        
        # Check if app is enabled
        if pm list packages -e | grep -q "$APP_PACKAGE"; then
            log_message "✓ ViPER4Android app enabled"
            return 0
        else
            error_message "✗ ViPER4Android app disabled"
            return 1
        fi
    else
        error_message "✗ ViPER4Android app not installed"
        return 1
    fi
}

# Main execution
main() {
    log_message "Starting ViPER4Android diagnostics..."
    echo "========================================"
    
    # Run all checks
    local all_checks_passed=true
    
    if ! check_module_status; then
        all_checks_passed=false
    fi
    
    if ! check_driver_installation; then
        all_checks_passed=false
    fi
    
    if ! check_xml_patching; then
        all_checks_passed=false
    fi
    
    if ! check_sepolicy_status; then
        all_checks_passed=false
    fi
    
    if ! check_app_installation; then
        all_checks_passed=false
    fi
    
    echo "========================================"
    
    # Final decision
    if $all_checks_passed; then
        log_message "🎉 All checks passed! Starting ViPER4Android..."
        if am start -n "$APP_PACKAGE/$APP_ACTIVITY"; then
            log_message "✓ ViPER4Android opened successfully!"
        else
            error_message "✗ Failed to open ViPER4Android"
        fi
    else
        error_message "❌ Some checks failed. ViPER4Android may not work properly."
        log_message "Please reinstall the module or download the latest version:"
        
        # Ask user if they want to download
        log_message "Would you like to download the latest version? (y/n)"
        read -r response
        case $response in
            [yY]|[yY][eE][sS])
                log_message "Opening download page..."
                am start -a android.intent.action.VIEW -d "$DOWNLOAD_URL"
                ;;
            *)
                log_message "You can download manually from: $DOWNLOAD_URL"
                ;;
        esac
    fi
}

# Check if we're in a proper environment
if [ "$(whoami)" != "root" ] && [ "$(whoami)" != "shell" ]; then
    error_message "This script requires root privileges"
    exit 1
fi

# Run main function
main