; Inno Setup Script para o Nave Browser (OZATI)
; Compilador oficial para gerar o instalador Nave-Setup.exe em 10 segundos.

#define MyAppName "Nave"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "OZATI"
#define MyAppURL "https://ozati.co/#nave"
#define MyAppExeName "chrome.exe"

[Setup]
AppId={{E581373A-4F3D-4A42-BA63-125A3440DF01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\Nave
DisableProgramGroupPage=yes
OutputDir=..\dist_installer
OutputBaseFilename=Nave-Setup
SetupIconFile=..\assets\nave.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\bin\engine\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\assets\nave.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --disable-background-networking --disable-sync"; IconFilename: "{app}\nave.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Parameters: "--enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --disable-background-networking --disable-sync"; IconFilename: "{app}\nave.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
