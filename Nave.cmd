@echo off
set "ROOT=%~dp0"
set "ENGINE=%ROOT%bin\engine\chrome.exe"
if not exist "%ENGINE%" set "ENGINE=%ROOT%engine\chrome.exe"
if not exist "%ENGINE%" set "ENGINE=%ROOT%chrome.exe"

set "PROFILE=%ROOT%profile_data"
set "EXTENSIONS=%ROOT%extensions\nave_core,%ROOT%extensions\nave_theme"

start "" "%ENGINE%" ^
  --user-data-dir="%PROFILE%" ^
  --load-extension="%EXTENSIONS%" ^
  --enable-gpu-rasterization ^
  --enable-zero-copy ^
  --ignore-gpu-blocklist ^
  --enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization,BackForwardCache,Prerender2,HighEfficiencyModeAvailable,DnsOverHttps ^
  --dns-over-https-templates="https://cloudflare-dns.com/dns-query" ^
  --extension-mime-request-handling=always-prompt-for-install ^
  --disable-background-networking ^
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
  %*
