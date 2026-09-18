<#
.SYNOPSIS
    Script de InicializaÃ§Ã£o e Montagem do Motor Chromium para o Nave Browser.
.DESCRIPTION
    Baixa a base ultra-rÃ¡pida do Chromium x64, injeta as flags de aceleraÃ§Ã£o por hardware,
    configura as extensÃµes nativas (Nave Shield e Dark Theme), injeta initial_preferences
    e gera o atalho oficial.
#>

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$binDir = Join-Path $root "bin"
$assetsDir = Join-Path $root "assets"
$userDataDir = Join-Path $root "profile_data"
$extDir = Join-Path $root "extensions"
$naveExe = Join-Path $root "Nave.exe"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   NAVE BROWSER â€¢ Setup do Motor Chromium" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

# 1. URL do Chromium x64 limpo (sem telemetria)
$version = "151.0.7922.173-1.1"
$zipUrl = "https://github.com/ungoogled-software/ungoogled-chromium-windows/releases/download/$version/ungoogled-chromium_${version}_windows_x64.zip"
$zipPath = Join-Path $binDir "chromium_base.zip"
$extractTarget = Join-Path $binDir "engine"

if (-not (Test-Path $extractTarget)) {
    Write-Host "[1/4] Baixando nÃºcleo Chromium limpo e otimizado ($version)..." -ForegroundColor Yellow
    if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
    curl.exe -L --progress-bar -o $zipPath $zipUrl

    Write-Host "[2/4] Extraindo arquivos do motor..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $extractTarget -Force
    Remove-Item $zipPath -Force
    
    # Ajusta o diretÃ³rio se houver pasta interna
    $subDir = Get-ChildItem -Path $extractTarget -Directory | Select-Object -First 1
    if ($subDir) {
        Get-ChildItem -Path $subDir.FullName | Move-Item -Destination $extractTarget -Force
        Remove-Item $subDir.FullName -Force -Recurse
    }
} else {
    Write-Host "[1/4] Motor Chromium jÃ¡ presente em $extractTarget" -ForegroundColor Green
}

# 2. Configurar initial_preferences
$prefSource = Join-Path $assetsDir "initial_preferences.json"
$prefTarget = Join-Path $extractTarget "initial_preferences"
if (Test-Path $prefSource) {
    Copy-Item $prefSource $prefTarget -Force
}

# 3. Compilar Launcher Nativo Nave.exe
Write-Host "[2/4] Verificando executÃ¡vel nativo Nave.exe..." -ForegroundColor Yellow
$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$srcLauncher = Join-Path $root "src_launcher\Program.cs"
$icoPath = Join-Path $assetsDir "nave.ico"

if (Test-Path $cscPath -and Test-Path $srcLauncher) {
    & $cscPath /nologo /target:winexe /win32icon:$icoPath /out:$naveExe $srcLauncher
    Write-Host "Launcher nativo Nave.exe atualizado com sucesso." -ForegroundColor Green
}

# 3.1 Injetar ícone e identidade oficial da Nave no motor Chromium
$rceditPath = Join-Path $binDir "rcedit-x64.exe"
$chromeExe = Join-Path $extractTarget "chrome.exe"
if (Test-Path $rceditPath -and Test-Path $chromeExe) {
    Write-Host "Injetando icone e identidade oficial da Nave no motor chrome.exe..." -ForegroundColor Yellow
    & $rceditPath $chromeExe --set-icon $icoPath `
        --set-version-string "FileDescription" "Nave - O Navegador Desktop da OZATI" `
        --set-version-string "ProductName" "Nave" `
        --set-version-string "CompanyName" "OZATI" `
        --set-version-string "LegalCopyright" "Copyright (C) 2026 OZATI"
    & $rceditPath $naveExe --set-icon $icoPath `
        --set-version-string "FileDescription" "Nave Launcher" `
        --set-version-string "ProductName" "Nave" `
        --set-version-string "CompanyName" "OZATI" `
        --set-version-string "LegalCopyright" "Copyright (C) 2026 OZATI"
}

# 4. Criar o Launcher CMD alternativo
Write-Host "[3/4] Atualizando Nave.cmd com flags de aceleraÃ§Ã£o mÃ¡xima..." -ForegroundColor Yellow

$coreExt = Join-Path $extDir "nave_core"
$themeExt = Join-Path $extDir "nave_theme"
$extList = "$coreExt,$themeExt"
$chromeExe = Join-Path $extractTarget "chrome.exe"

$launcherCmd = Join-Path $root "Nave.cmd"
$launcherScript = @"
@echo off
start "" "$chromeExe" ^
  --user-data-dir="$userDataDir" ^
  --load-extension="$extList" ^
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
"@

Set-Content -Path $launcherCmd -Value $launcherScript -Encoding ASCII

# 5. Criar Atalho na Ãrea de Trabalho com o Ãcone Oficial da Nave
Write-Host "[4/4] Criando atalho na Ãrea de Trabalho..." -ForegroundColor Yellow

$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Nave.lnk"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
if (Test-Path $naveExe) {
    $shortcut.TargetPath = $naveExe
    $shortcut.WorkingDirectory = $root
    $shortcut.IconLocation = "$naveExe,0"
} else {
    $shortcut.TargetPath = $chromeExe
    $shortcut.Arguments = "--user-data-dir=`"$userDataDir`" --load-extension=`"$extList`" --enable-gpu-rasterization --enable-zero-copy --ignore-gpu-blocklist --enable-features=VaapiVideoDecoder,ParallelDownloading,CanvasOopRasterization,BackForwardCache,Prerender2,HighEfficiencyModeAvailable,DnsOverHttps --dns-over-https-templates=`"https://cloudflare-dns.com/dns-query`" --extension-mime-request-handling=always-prompt-for-install --disable-background-networking --disable-sync --force-dark-mode"
    $shortcut.IconLocation = "$icoPath,0"
    $shortcut.WorkingDirectory = $extractTarget
}
$shortcut.Description = "Nave - O Navegador Mais RÃ¡pido"
$shortcut.Save()

Write-Host "==========================================" -ForegroundColor Green
Write-Host "   NAVE BROWSER CONFIGURADO COM SUCESSO!   " -ForegroundColor Green
Write-Host "   Atalho criado: $shortcutPath           " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Green

