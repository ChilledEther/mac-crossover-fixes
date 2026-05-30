@echo off
title CrossOver Gamepad Fix Toggler
echo ===================================================
echo   CrossOver Gamepad Detection Patch Toggler
echo ===================================================
echo.

reg query "HKCU\Software\Wine\DllOverrides" /v "windows.gaming.input" >nul 2>&1
if %errorlevel% equ 0 (
    echo [STATUS] Gamepad fix is currently [ENABLED] (windows.gaming.input is disabled).
    echo [ACTION] Disabling gamepad fix (restoring default windows.gaming.input behavior)...
    reg delete "HKCU\Software\Wine\DllOverrides" /v "windows.gaming.input" /f >nul
    echo.
    echo [SUCCESS] Gamepad fix has been DISABLED.
) else (
    echo [STATUS] Gamepad fix is currently [DISABLED] (windows.gaming.input is enabled).
    echo [ACTION] Enabling gamepad fix (blocking windows.gaming.input, forcing XInput fallback)...
    reg add "HKCU\Software\Wine\DllOverrides" /v "windows.gaming.input" /t REG_SZ /d "" /f >nul
    echo.
    echo [SUCCESS] Gamepad fix has been ENABLED.
)

echo.
echo Please reboot this bottle to ensure changes are applied to running games.
echo ===================================================
pause
