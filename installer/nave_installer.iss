; Inno Setup Script para o Nave Browser (OZATI)
; Compilador oficial para gerar o instalador Nave-Setup.exe profissional

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
UninstallDisplayIcon={app}\assets\nave.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\Nave.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Nave.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Criar-Atalho-Area-de-Trabalho.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\assets\nave.ico"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "..\assets\nave.svg"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "..\bin\engine\*"; DestDir: "{app}\bin\engine"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\extensions\*"; DestDir: "{app}\extensions"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\nave.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\nave.ico"; Tasks: desktopicon

[Registry]
; Registra o Nave como Navegador Oficial no Windows
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave"; ValueType: string; ValueName: ""; ValueData: "Nave"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\assets\nave.ico,0"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\Nave.exe"""
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "Nave - O navegador desktop mais rápido da OZATI"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities"; ValueType: string; ValueName: "ApplicationIcon"; ValueData: "{app}\assets\nave.ico,0"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "Nave"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\StartMenu"; ValueType: string; ValueName: "StartMenuInternet"; ValueData: "Nave"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\URLAssociations"; ValueType: string; ValueName: "http"; ValueData: "NaveHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\URLAssociations"; ValueType: string; ValueName: "https"; ValueData: "NaveHTML"
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "Nave"; ValueData: "Software\Clients\StartMenuInternet\Nave\Capabilities"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
