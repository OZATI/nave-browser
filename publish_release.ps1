param (
    [Parameter(Mandatory=$true, HelpMessage="Número da nova versão (ex: 1.0.1)")]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [string]$Notes = "Atualização oficial de desempenho e segurança do Nave."
)

$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "    DISPARANDO ATUALIZAÇÃO GLOBAL DO NAVE (v$Version)   " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$root = $PSScriptRoot
$naveSiteDir = "C:\Users\kenio\OneDrive\Documentos\nave.ozati.co"
$ozatiSiteDir = "C:\Users\kenio\OneDrive\Documentos\ozati.co"

# 1. Atualizar versão no código-fonte C#
Write-Host "1. Atualizando versão no lançador C#..." -ForegroundColor Yellow
$progPath = Join-Path $root "src_launcher\Program.cs"
(Get-Content $progPath) -replace 'public const string CurrentVersion = "[^"]+"', "public const string CurrentVersion = `"$Version`"" | Set-Content $progPath

# 2. Atualizar versão no script do Inno Setup
Write-Host "2. Atualizando versão no instalador Inno Setup..." -ForegroundColor Yellow
$issPath = Join-Path $root "installer\nave_installer.iss"
(Get-Content $issPath) -replace '#define MyAppVersion "[^"]+"', "#define MyAppVersion `"$Version`"" | Set-Content $issPath

# 3. Recompilar Nave.exe e aplicar metadados
Write-Host "3. Compilando Nave.exe com ícone e auto-updater..." -ForegroundColor Yellow
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /target:winexe /win32icon:(Join-Path $root "assets\nave.ico") /r:System.Windows.Forms.dll /out:(Join-Path $root "Nave.exe") $progPath
& "C:\Users\kenio\.gemini\antigravity-cli\brain\fc9b91b0-80eb-4685-bcd5-7536f50ca8bc\scratch\node_modules\rcedit\bin\rcedit-x64.exe" (Join-Path $root "Nave.exe") --set-icon (Join-Path $root "assets\nave.ico") --set-version-string "FileDescription" "Nave Browser" --set-version-string "ProductName" "Nave" --set-version-string "CompanyName" "OZATI" --set-file-version $Version --set-product-version $Version

# 4. Compilar instalador oficial Nave-Setup.exe
Write-Host "4. Compilando instalador Nave-Setup.exe com Inno Setup..." -ForegroundColor Yellow
& "C:\Users\kenio\AppData\Local\Programs\Inno Setup 6\ISCC.exe" $issPath

$setupExe = Join-Path $root "dist_installer\Nave-Setup.exe"
if (-not (Test-Path $setupExe)) {
    throw "Erro: Nave-Setup.exe não foi gerado!"
}

# 5. Publicar release oficial no GitHub
Write-Host "5. Publicando Release v$Version no GitHub..." -ForegroundColor Yellow
gh release create "v$Version" $setupExe --title "Nave v$Version - Oficial" --notes "$Notes" --repo OZATI/nave-browser

# 6. Atualizar version.json para disparar a atualização nos computadores de todos os usuários
Write-Host "6. Atualizando version.json para disparo imediato..." -ForegroundColor Yellow
$dateStr = (Get-Date).ToString("yyyy-MM-dd")
$jsonContent = @"
{
  "version": "$Version",
  "release_date": "$dateStr",
  "download_url": "https://github.com/OZATI/nave-browser/releases/download/v$Version/Nave-Setup.exe",
  "notes": "$Notes"
}
"@

Set-Content (Join-Path $naveSiteDir "version.json") $jsonContent -Encoding UTF8
Set-Content (Join-Path $ozatiSiteDir "public\nave\version.json") $jsonContent -Encoding UTF8

# 7. Git commit e push
Write-Host "7. Propagando atualização para os servidores da OZATI..." -ForegroundColor Yellow
git -C $root add .
git -C $root commit -m "chore: release version $Version"
git -C $root push origin main

git -C $naveSiteDir add version.json
git -C $naveSiteDir commit -m "release: bump version to $Version for live auto-updater"
git -C $naveSiteDir push origin main

git -C $ozatiSiteDir add public/nave/version.json
git -C $ozatiSiteDir commit -m "release: bump Nave version to $Version"
git -C $ozatiSiteDir push origin main

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host " SUCESSO! VERSÃO $Version DISPARADA PARA O MUNDO INTEIRO! " -ForegroundColor Green
Write-Host " Todos os computadores instalados receberão a versão     " -ForegroundColor Green
Write-Host " $Version automaticamente em segundo plano!             " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
