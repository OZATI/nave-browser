@echo off
start "" "C:\Users\kenio\OneDrive\Documentos\nave-browser\bin\engine\chrome.exe" ^
  --user-data-dir="C:\Users\kenio\OneDrive\Documentos\nave-browser\profile_data" ^
  --enable-gpu-rasterization ^
  --enable-zero-copy ^
  --ignore-gpu-blocklist ^
  --enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization ^
  --disable-background-networking ^
  --disable-domain-reliability ^
  --disable-sync ^
  --disk-cache-size=1073741824 ^
  "https://ozati.co" ^
  %*
