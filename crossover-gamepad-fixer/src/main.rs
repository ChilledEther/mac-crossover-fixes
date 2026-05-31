#![windows_subsystem = "windows"]

mod patch;

use std::ffi::OsStr;
use std::os::windows::ffi::OsStrExt;
use patch::{get_all_patches, Patch};

// Win32 Constants
const WS_OVERLAPPEDWINDOW: u32 = 0x00CF0000;
const WS_VISIBLE: u32 = 0x10000000;
const WS_CHILD: u32 = 0x40000000;
const BS_AUTOCHECKBOX: u32 = 0x00000003;
const BS_DEFPUSHBUTTON: u32 = 0x00000001;
const BM_GETCHECK: u32 = 0x00F0;
const BM_SETCHECK: u32 = 0x00F1;
const BST_CHECKED: usize = 0x0001;
const WM_CREATE: u32 = 0x0001;
const WM_DESTROY: u32 = 0x0002;
const WM_COMMAND: u32 = 0x0111;
const WM_SETFONT: u32 = 0x0030;
const WM_CTLCOLORSTATIC: u32 = 0x0138;
const COLOR_3DFACE: i32 = 15;
const CS_HREDRAW: u32 = 2;
const CS_VREDRAW: u32 = 1;
const IDC_ARROW: usize = 32512;

// Static font and window handles for global lifecycle
static mut STATUS_LABEL_HWND: *mut std::ffi::c_void = std::ptr::null_mut();
static mut TITLE_FONT: *mut std::ffi::c_void = std::ptr::null_mut();
static mut NORMAL_FONT: *mut std::ffi::c_void = std::ptr::null_mut();
static mut DESC_FONT: *mut std::ffi::c_void = std::ptr::null_mut();

#[repr(C)]
struct WNDCLASSEXW {
    cbSize: u32,
    style: u32,
    lpfnWndProc: Option<unsafe extern "system" fn(*mut std::ffi::c_void, u32, usize, isize) -> isize>,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: *mut std::ffi::c_void,
    hIcon: *mut std::ffi::c_void,
    hCursor: *mut std::ffi::c_void,
    hbrBackground: *mut std::ffi::c_void,
    lpszMenuName: *const u16,
    lpszClassName: *const u16,
    hIconSm: *mut std::ffi::c_void,
}

#[repr(C)]
struct MSG {
    hwnd: *mut std::ffi::c_void,
    message: u32,
    wParam: usize,
    lParam: isize,
    time: u32,
    pt: POINT,
}

#[repr(C)]
struct POINT {
    x: i32,
    y: i32,
}

#[link(name = "user32")]
extern "system" {
    fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) -> u16;
    fn CreateWindowExW(
        dwExStyle: u32,
        lpClassName: *const u16,
        lpWindowName: *const u16,
        dwStyle: u32,
        X: i32,
        Y: i32,
        nWidth: i32,
        nHeight: i32,
        hWndParent: *mut std::ffi::c_void,
        hMenu: *mut std::ffi::c_void,
        hInstance: *mut std::ffi::c_void,
        lpParam: *mut std::ffi::c_void,
    ) -> *mut std::ffi::c_void;
    fn DefWindowProcW(
        hWnd: *mut std::ffi::c_void,
        Msg: u32,
        wParam: usize,
        lParam: isize,
    ) -> isize;
    fn ShowWindow(hWnd: *mut std::ffi::c_void, nCmdShow: i32) -> i32;
    fn UpdateWindow(hWnd: *mut std::ffi::c_void) -> i32;
    fn GetMessageW(
        lpMsg: *mut MSG,
        hWnd: *mut std::ffi::c_void,
        wMsgFilterMin: u32,
        wMsgFilterMax: u32,
    ) -> i32;
    fn TranslateMessage(lpMsg: *const MSG) -> i32;
    fn DispatchMessageW(lpMsg: *const MSG) -> isize;
    fn PostQuitMessage(nExitCode: i32);
    fn SendMessageW(
        hWnd: *mut std::ffi::c_void,
        Msg: u32,
        wParam: usize,
        lParam: isize,
    ) -> isize;
    fn SetWindowTextW(hWnd: *mut std::ffi::c_void, lpString: *const u16) -> i32;
    fn LoadCursorW(hInstance: *mut std::ffi::c_void, lpCursorName: *const u16) -> *mut std::ffi::c_void;
    fn LoadIconW(hInstance: *mut std::ffi::c_void, lpIconName: *const u16) -> *mut std::ffi::c_void;
    fn GetSysColorBrush(nIndex: i32) -> *mut std::ffi::c_void;
    fn MessageBoxW(
        hWnd: *mut std::ffi::c_void,
        lpText: *const u16,
        lpCaption: *const u16,
        uType: u32,
    ) -> i32;
}

#[link(name = "kernel32")]
extern "system" {
    fn GetModuleHandleW(lpModuleName: *const u16) -> *mut std::ffi::c_void;
}

#[link(name = "gdi32")]
extern "system" {
    fn CreateFontW(
        cHeight: i32,
        cWidth: i32,
        cEscapement: i32,
        cOrientation: i32,
        cWeight: i32,
        bItalic: u32,
        bUnderline: u32,
        bStrikeOut: u32,
        iCharSet: u32,
        iOutPrecision: u32,
        iClipPrecision: u32,
        iQuality: u32,
        iPitchAndFamily: u32,
        pszFaceName: *const u16,
    ) -> *mut std::ffi::c_void;
    fn DeleteObject(ho: *mut std::ffi::c_void) -> i32;
    fn SetBkMode(hdc: *mut std::ffi::c_void, mode: i32) -> i32;
}

fn to_wide(s: &str) -> Vec<u16> {
    OsStr::new(s)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect()
}

unsafe extern "system" fn wnd_proc(
    hwnd: *mut std::ffi::c_void,
    msg: u32,
    wparam: usize,
    lparam: isize,
) -> isize {
    match msg {
        WM_CREATE => {
            let hinstance = GetModuleHandleW(std::ptr::null());

            // Create Segoe UI fonts for sleek modern look instead of standard Windows 95 font
            TITLE_FONT = CreateFontW(
                22, 0, 0, 0, 700, // FW_BOLD
                0, 0, 0, 1, 0, 0, 2, 0,
                to_wide("Segoe UI").as_ptr(),
            );
            NORMAL_FONT = CreateFontW(
                16, 0, 0, 0, 400, // FW_NORMAL
                0, 0, 0, 1, 0, 0, 2, 0,
                to_wide("Segoe UI").as_ptr(),
            );
            DESC_FONT = CreateFontW(
                14, 0, 0, 0, 400, // FW_NORMAL small
                0, 0, 0, 1, 0, 0, 2, 0,
                to_wide("Segoe UI").as_ptr(),
            );

            // Title label
            let hwnd_title = CreateWindowExW(
                0,
                to_wide("STATIC").as_ptr(),
                to_wide("macOS CrossOver Fixer").as_ptr(),
                WS_CHILD | WS_VISIBLE,
                20, 15, 460, 25,
                hwnd,
                std::ptr::null_mut(),
                hinstance,
                std::ptr::null_mut(),
            );
            SendMessageW(hwnd_title, WM_SETFONT, TITLE_FONT as usize, 1);

            // Subtitle label
            let hwnd_sub = CreateWindowExW(
                0,
                to_wide("STATIC").as_ptr(),
                to_wide("Toggle compatibility fixes for this bottle:").as_ptr(),
                WS_CHILD | WS_VISIBLE,
                20, 45, 460, 20,
                hwnd,
                std::ptr::null_mut(),
                hinstance,
                std::ptr::null_mut(),
            );
            SendMessageW(hwnd_sub, WM_SETFONT, NORMAL_FONT as usize, 1);

            // Dynamically construct checkboxes and descriptions for all registered patches
            let patches = get_all_patches();
            for (i, patch) in patches.iter().enumerate() {
                let y_start = 80 + (i as i32) * 85;

                // Checkbox
                let hwnd_chk = CreateWindowExW(
                    0,
                    to_wide("BUTTON").as_ptr(),
                    to_wide(patch.name()).as_ptr(),
                    WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
                    20, y_start, 460, 20,
                    hwnd,
                    (100 + i) as *mut std::ffi::c_void,
                    hinstance,
                    std::ptr::null_mut(),
                );
                SendMessageW(hwnd_chk, WM_SETFONT, NORMAL_FONT as usize, 1);

                if patch.is_enabled().unwrap_or(false) {
                    SendMessageW(hwnd_chk, BM_SETCHECK, BST_CHECKED, 0);
                }

                // Description Text
                let hwnd_desc = CreateWindowExW(
                    0,
                    to_wide("STATIC").as_ptr(),
                    to_wide(patch.description()).as_ptr(),
                    WS_CHILD | WS_VISIBLE,
                    40, y_start + 22, 440, 45,
                    hwnd,
                    std::ptr::null_mut(),
                    hinstance,
                    std::ptr::null_mut(),
                );
                SendMessageW(hwnd_desc, WM_SETFONT, DESC_FONT as usize, 1);
            }

            // Bottom Status Text Label
            STATUS_LABEL_HWND = CreateWindowExW(
                0,
                to_wide("STATIC").as_ptr(),
                to_wide("Status: Ready. Toggle settings above to apply fixes instantly.").as_ptr(),
                WS_CHILD | WS_VISIBLE,
                20, 345, 320, 35,
                hwnd,
                std::ptr::null_mut(),
                hinstance,
                std::ptr::null_mut(),
            );
            SendMessageW(STATUS_LABEL_HWND, WM_SETFONT, DESC_FONT as usize, 1);

            // Reboot Bottle Button
            let hwnd_reboot = CreateWindowExW(
                0,
                to_wide("BUTTON").as_ptr(),
                to_wide("Reboot Bottle").as_ptr(),
                WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
                350, 340, 130, 30,
                hwnd,
                200 as *mut std::ffi::c_void,
                hinstance,
                std::ptr::null_mut(),
            );
            SendMessageW(hwnd_reboot, WM_SETFONT, NORMAL_FONT as usize, 1);

            0
        }
        WM_CTLCOLORSTATIC => {
            // Transparent background for static label texts to look premium
            SetBkMode(wparam as *mut std::ffi::c_void, 1);
            GetSysColorBrush(COLOR_3DFACE) as isize
        }
        WM_COMMAND => {
            let control_id = wparam & 0xFFFF;
            let patches = get_all_patches();
            
            if control_id >= 100 && control_id < 100 + patches.len() {
                let idx = control_id - 100;
                let patch = &patches[idx];

                let hwnd_chk = lparam as *mut std::ffi::c_void;
                let is_checked = SendMessageW(hwnd_chk, BM_GETCHECK, 0, 0) == BST_CHECKED as isize;

                let res = if is_checked {
                    patch.enable()
                } else {
                    patch.disable()
                };

                match res {
                    Ok(_) => {
                        let status_msg = if is_checked {
                            format!("Status: Enabled '{}'. Reboot bottle to apply.", patch.name())
                        } else {
                            format!("Status: Disabled '{}'. Reboot bottle to apply.", patch.name())
                        };
                        SetWindowTextW(STATUS_LABEL_HWND, to_wide(&status_msg).as_ptr());
                    }
                    Err(e) => {
                        MessageBoxW(
                            hwnd,
                            to_wide(&format!("Error toggling patch: {}", e)).as_ptr(),
                            to_wide("Registry Error").as_ptr(),
                            0x00000010, // MB_ICONERROR
                        );
                    }
                }
            } else if control_id == 200 {
                // Soft Wineboot Reboot
                SetWindowTextW(STATUS_LABEL_HWND, to_wide("Status: Restarting Wine bottle...").as_ptr());
                
                std::process::Command::new("wineboot")
                    .arg("-r")
                    .spawn()
                    .ok();

                MessageBoxW(
                    hwnd,
                    to_wide("A reboot command has been sent to the bottle.\n\nGames will apply the updated patches upon launching next time.").as_ptr(),
                    to_wide("Reboot Bottle").as_ptr(),
                    0x00000040, // MB_ICONINFORMATION
                );
            }
            0
        }
        WM_DESTROY => {
            // Delete GDI fonts to prevent resource leaks
            if !TITLE_FONT.is_null() { DeleteObject(TITLE_FONT); }
            if !NORMAL_FONT.is_null() { DeleteObject(NORMAL_FONT); }
            if !DESC_FONT.is_null() { DeleteObject(DESC_FONT); }

            PostQuitMessage(0);
            0
        }
        _ => DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}

fn main() {
    unsafe {
        let hinstance = GetModuleHandleW(std::ptr::null());

        // Load custom embedded icon from resource file (1 is standard app icon)
        let hicon = LoadIconW(hinstance, 1 as *const u16);
        let hcursor = LoadCursorW(std::ptr::null_mut(), IDC_ARROW as *const u16);

        let class_name = to_wide("MacCrossOverFixerClass");
        let wnd_class = WNDCLASSEXW {
            cbSize: std::mem::size_of::<WNDCLASSEXW>() as u32,
            style: CS_HREDRAW | CS_VREDRAW,
            lpfnWndProc: Some(wnd_proc),
            cbClsExtra: 0,
            cbWndExtra: 0,
            hInstance: hinstance,
            hIcon: hicon,
            hCursor: hcursor,
            hbrBackground: GetSysColorBrush(COLOR_3DFACE),
            lpszMenuName: std::ptr::null(),
            lpszClassName: class_name.as_ptr(),
            hIconSm: hicon,
        };

        if RegisterClassExW(&wnd_class) == 0 {
            MessageBoxW(
                std::ptr::null_mut(),
                to_wide("Failed to register window class!").as_ptr(),
                to_wide("Fatal Error").as_ptr(),
                0x00000010, // MB_ICONERROR
            );
            return;
        }

        // WS_OVERLAPPEDWINDOW without resize and maximize options for a sleek fixed-size window design
        let hwnd = CreateWindowExW(
            0,
            class_name.as_ptr(),
            to_wide("macOS CrossOver Fixer").as_ptr(),
            WS_OVERLAPPEDWINDOW & !0x00050000, // disables WS_MAXIMIZEBOX and WS_THICKFRAME (resizing)
            100, 100, 516, 439, // client width 500, height 400 + titlebar & border padding
            std::ptr::null_mut(),
            std::ptr::null_mut(),
            hinstance,
            std::ptr::null_mut(),
        );

        if hwnd.is_null() {
            MessageBoxW(
                std::ptr::null_mut(),
                to_wide("Failed to create main window!").as_ptr(),
                to_wide("Fatal Error").as_ptr(),
                0x00000010, // MB_ICONERROR
            );
            return;
        }

        ShowWindow(hwnd, 1); // SW_SHOWNORMAL = 1
        UpdateWindow(hwnd);

        let mut msg = MSG {
            hwnd: std::ptr::null_mut(),
            message: 0,
            wParam: 0,
            lParam: 0,
            time: 0,
            pt: POINT { x: 0, y: 0 },
        };

        while GetMessageW(&mut msg, std::ptr::null_mut(), 0, 0) > 0 {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
}
