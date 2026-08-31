; Inno Setup script for Keep Track

#define MyAppName "Keep Track"
#define MyAppVersion "0.9.0"
#define MyAppPublisher "Khesir"
#define MyAppURL "https://keep-track.khesir.com/"
#define MyAppExeName "keep_track.exe"

[Setup]
AppId={{A8947B06-4B99-45BB-8600-8A7D4B7D06D1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputDir=C:\Users\AJ\Documents\Projects\KeepTrack\installers
OutputBaseFilename=KeepTrack-v0.9.0
SetupIconFile=C:\Users\AJ\Documents\Projects\KeepTrack\assets\icon\icon.ico
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\app_links_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\connectivity_plus_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\file_selector_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\flutter_secure_storage_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\permission_handler_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\screen_retriever_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\local_notifier_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\AJ\Documents\Projects\KeepTrack\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
