@echo off
set "SCRIPT_DIR=%~dp0"
set "ENGINE=%SCRIPT_DIR%bin\engine\chrome.exe"
if not exist "%ENGINE%" set "ENGINE=%SCRIPT_DIR%engine\chrome.exe"
if not exist "%ENGINE%" set "ENGINE=%SCRIPT_DIR%chrome.exe"
set "PROFILE=%LOCALAPPDATA%\Nave\User Data"
set "CORE_EXT=%SCRIPT_DIR%extensions\nave_core"
set "THEME_EXT=%SCRIPT_DIR%extensions\nave_theme"

set "EXT_ARG="
if exist "%CORE_EXT%" (
    if exist "%THEME_EXT%" (
        set "EXT_ARG=--load-extension=""%CORE_EXT%,%THEME_EXT%"""
    ) else (
        set "EXT_ARG=--load-extension=""%CORE_EXT%"""
    )
)

start "" "%ENGINE%" ^
    --user-data-dir="%PROFILE%" ^
    --disable-search-engine-choice-screen ^
    --enable-gpu-rasterization ^
    --enable-zero-copy ^
    --ignore-gpu-blocklist ^
    --enable-features=SidePanel,SidePanelPinning,SideSearch,SidePanelCompanion,ChromeRefresh2023,ChromeWebuiRefresh2023,PowerBookmarks,VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization,BackForwardCache,Prerender2,HighEfficiencyModeAvailable ^
    --disable-domain-reliability ^
    --disable-component-update ^
    --disable-sync ^
    --disable-breakpad ^
    --disable-logging ^
    --metrics-recording-only ^
    --no-first-run ^
    --no-default-browser-check ^
    --force-dark-mode ^
    --disk-cache-size=1073741824 ^
    %EXT_ARG% %*
