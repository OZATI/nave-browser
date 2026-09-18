; Inno Setup Script para o Nave Browser (OZATI)
; Compilador oficial para gerar o instalador Nave-Setup.exe de alta performance.

#define MyAppName "Nave"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "OZATI"
#define MyAppURL "https://nave.ozati.co"
#define MyAppExeName "Nave.exe"

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
Source: "..\Nave.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\engine\*"; DestDir: "{app}\bin\engine"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\extensions\*"; DestDir: "{app}\extensions"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\assets\nave.ico"; DestDir: "{app}\assets"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\nave.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\nave.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
