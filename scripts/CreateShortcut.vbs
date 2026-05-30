' CreateShortcut.vbs
' Helper script to create a Windows Start Menu shortcut pointing to wineconsole and ToggleGamepadFix.bat
'
' Usage: cscript.exe CreateShortcut.vbs [ShortcutName] [BatchFilePath] [IconPath]

Set args = WScript.Arguments
If args.Count < 2 Then
    WScript.Echo "Usage: cscript.exe CreateShortcut.vbs [ShortcutName] [BatchFilePath]"
    WScript.Quit 1
End If

Dim shortcutName, batchPath
shortcutName = args(0)
batchPath = args(1)

Set Shell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Get the user's Start Menu Programs folder
Dim appData, startMenuPath
appData = Shell.ExpandEnvironmentStrings("%APPDATA%")
startMenuPath = appData & "\Microsoft\Windows\Start Menu\Programs"

If Not FSO.FolderExists(startMenuPath) Then
    ' Fallback if Programs folder doesn't exist
    startMenuPath = appData & "\Microsoft\Windows\Start Menu"
End If

Dim lnkPath
lnkPath = startMenuPath & "\" & shortcutName & ".lnk"

WScript.Echo "Creating shortcut at: " & lnkPath
WScript.Echo "Target: wineconsole.exe"
WScript.Echo "Arguments: " & batchPath

Set Link = Shell.CreateShortcut(lnkPath)
Link.TargetPath = "C:\windows\system32\wineconsole.exe"
Link.Arguments = batchPath
Link.WorkingDirectory = FSO.GetParentFolderName(batchPath)
Link.Description = "Toggle CrossOver Gamepad Fix"

' Resolve icon location
Dim iconPath, parentDir
parentDir = FSO.GetParentFolderName(batchPath)

If args.Count >= 3 Then
    iconPath = args(2)
Else
    Dim checkIcon
    checkIcon = parentDir & "\GamepadFix.ico"
    If FSO.FileExists(checkIcon) Then
        iconPath = checkIcon
    End If
End If

If iconPath <> "" Then
    WScript.Echo "Icon: " & iconPath
    Link.IconLocation = iconPath
End If

Link.Save

WScript.Echo "Shortcut created successfully!"
