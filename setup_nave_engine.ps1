<#
.SYNOPSIS
    Script de Inicialização e Montagem do Motor Chromium para o Nave Browser (OZATI).
.DESCRIPTION
    Baixa a base ultra-rápida do Chromium x64, injeta as flags de aceleração por hardware
    e configura o ambiente do Nave Browser.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$binDir = Join-Path $root "bin"
$assetsDir = Join-Path $root "assets"
$userDataDir = Join-Path $root "profile_data"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   NAVE BROWSER • Setup do Motor Chromium" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

# 1. URL do Chromium x64 limpo (sem telemetria)
$version = "151.0.7922.173-1.1"
$zipUrl = "https://github.com/ungoogled-software/ungoogled-chromium-windows/releases/download/$version/ungoogled-chromium_${version}_windows_x64.zip"
$zipPath = Join-Path $binDir "chromium_base.zip"
$extractTarget = Join-Path $binDir "engine"

if (-not (Test-Path $extractTarget)) {
    Write-Host "[1/4] Baixando núcleo Chromium limpo e otimizado ($version)..." -ForegroundColor Yellow
    curl.exe -L --progress-bar -o $zipPath $zipUrl

    Write-Host "[2/4] Extraindo arquivos do motor..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $extractTarget -Force
    Remove-Item $zipPath -Force
    
    # Ajusta o diretório se houver pasta interna
    $subDir = Get-ChildItem -Path $extractTarget -Directory | Select-Object -First 1
    if ($subDir) {
        Get-ChildItem -Path $subDir.FullName | Move-Item -Destination $extractTarget -Force
        Remove-Item $subDir.FullName -Force -Recurse
    }
} else {
    Write-Host "[1/4] Motor Chromium já presente em $extractTarget" -ForegroundColor Green
}

# 2. Criar o Launcher Oficial com flags de velocidade máxima
Write-Host "[3/4] Criando o launcher Nave com aceleração de hardware total..." -ForegroundColor Yellow

$launcherCmd = Join-Path $root "Nave.cmd"
$chromeExe = Join-Path $extractTarget "chrome.exe"

$launcherScript = @"
@echo off
start "" "$chromeExe" ^
  --user-data-dir="$userDataDir" ^
  --enable-gpu-rasterization ^
  --enable-zero-copy ^
  --ignore-gpu-blocklist ^
  --enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization ^
  --disable-background-networking ^
  --disable-domain-reliability ^
  --disable-sync ^
  --disk-cache-size=1073741824 ^
  --app="https://ozati.co" ^
  %*
"@

Set-Content -Path $launcherCmd -Value $launcherScript -Encoding ASCII

# 3. Criar Atalho na Área de Trabalho com o Ícone Oficial da Nave
Write-Host "[4/4] Criando atalho na Área de Trabalho com o ícone oficial da Nave..." -ForegroundColor Yellow

$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Nave - OZATI.lnk"
$icoPath = Join-Path $assetsDir "nave.ico"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $chromeExe
$shortcut.Arguments = "--user-data-dir=`"$userDataDir`" --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization --disable-background-networking --disable-sync"
$shortcut.IconLocation = "$icoPath,0"
$shortcut.Description = "Nave - O Navegador da OZATI"
$shortcut.WorkingDirectory = $extractTarget
$shortcut.Save()

Write-Host "==========================================" -ForegroundColor Green
Write-Host "   NAVE BROWSER CONFIGURADO COM SUCESSO!   " -ForegroundColor Green
Write-Host "   Atalho criado: $shortcutPath           " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Green
