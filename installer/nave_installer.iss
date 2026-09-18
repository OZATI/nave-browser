; Inno Setup Script para o Nave Browser
; Compilador oficial para gerar o instalador Nave-Setup.exe com registro de navegador padrÃ£o no Windows.

#define MyAppName "Nave"
#define MyAppVersion "1.0.1"
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
Source: "..\assets\initial_preferences.json"; DestDir: "{app}\bin\engine"; DestName: "initial_preferences"; Flags: ignoreversion
Source: "..\bin\sqlite3.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\rcedit-x64.exe"; DestDir: "{app}\bin"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\nave.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\assets\nave.ico"; Tasks: desktopicon

[Registry]
; Registrar Nave como Cliente de Internet no Windows (StartMenuInternet)
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave"; ValueType: string; ValueData: "Nave"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\DefaultIcon"; ValueType: string; ValueData: "{app}\assets\nave.ico,0"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"""

; Capabilities para o Windows 10/11 reconhecer em "Aplicativos PadrÃ£o"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "Nave - Navegador desktop ultra rÃ¡pido, sem telemetria e com proteÃ§Ã£o ativa."
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities"; ValueType: string; ValueName: "ApplicationIcon"; ValueData: "{app}\assets\nave.ico,0"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "Nave"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\URLAssociations"; ValueType: string; ValueName: "http"; ValueData: "NaveHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\URLAssociations"; ValueType: string; ValueName: "https"; ValueData: "NaveHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\FileAssociations"; ValueType: string; ValueName: ".htm"; ValueData: "NaveHTML"
Root: HKCU; Subkey: "Software\Clients\StartMenuInternet\Nave\Capabilities\FileAssociations"; ValueType: string; ValueName: ".html"; ValueData: "NaveHTML"

; Registro do App em RegisteredApplications
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "Nave"; ValueData: "Software\Clients\StartMenuInternet\Nave\Capabilities"; Flags: uninsdeletevalue

; AssociaÃ§Ã£o de Classes NaveHTML
Root: HKCU; Subkey: "Software\Classes\NaveHTML"; ValueType: string; ValueData: "Nave HTML Document"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\NaveHTML\DefaultIcon"; ValueType: string; ValueData: "{app}\assets\nave.ico,0"
Root: HKCU; Subkey: "Software\Classes\NaveHTML\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

; Configurar Google como Mecanismo de Busca Oficial e Desativar Escolha DMA
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: dword; ValueName: "DefaultSearchProviderEnabled"; ValueData: "1"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: string; ValueName: "DefaultSearchProviderName"; ValueData: "Google"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: string; ValueName: "DefaultSearchProviderSearchURL"; ValueData: "https://www.google.com/search?q={{searchTerms}"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: string; ValueName: "DefaultSearchProviderSuggestURL"; ValueData: "https://www.google.com/complete/search?client=chrome&q={{searchTerms}"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: string; ValueName: "DefaultSearchProviderIconURL"; ValueData: "https://www.google.com/favicon.ico"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: string; ValueName: "DefaultSearchProviderKeyword"; ValueData: "google.com"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Chromium"; ValueType: dword; ValueName: "SearchEngineChoiceScreenEnabled"; ValueData: "0"; Flags: uninsdeletekeyifempty

Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: dword; ValueName: "DefaultSearchProviderEnabled"; ValueData: "1"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: string; ValueName: "DefaultSearchProviderName"; ValueData: "Google"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: string; ValueName: "DefaultSearchProviderSearchURL"; ValueData: "https://www.google.com/search?q={{searchTerms}"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: string; ValueName: "DefaultSearchProviderSuggestURL"; ValueData: "https://www.google.com/complete/search?client=chrome&q={{searchTerms}"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: string; ValueName: "DefaultSearchProviderIconURL"; ValueData: "https://www.google.com/favicon.ico"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: string; ValueName: "DefaultSearchProviderKeyword"; ValueData: "google.com"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Policies\Google\Chrome"; ValueType: dword; ValueName: "SearchEngineChoiceScreenEnabled"; ValueData: "0"; Flags: uninsdeletekeyifempty

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

