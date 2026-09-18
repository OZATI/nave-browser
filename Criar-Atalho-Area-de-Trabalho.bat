@echo off
setlocal
title Criando Atalho do Nave na Área de Trabalho...
echo ========================================================
echo         NAVE BROWSER - INSTALADOR DE ATALHO
echo ========================================================
echo.

set "TARGET_DIR=%~dp0"
set "EXE_PATH=%TARGET_DIR%Nave.exe"
set "ICON_PATH=%TARGET_DIR%assets\nave.ico"

if not exist "%EXE_PATH%" (
    echo ERRO: Nave.exe nao encontrado no diretorio:
    echo %TARGET_DIR%
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$desk = [Environment]::GetFolderPath('Desktop'); " ^
    "$startMenu = [Environment]::GetFolderPath('Programs'); " ^
    "$sc1 = $ws.CreateShortcut((Join-Path $desk 'Nave.lnk')); " ^
    "$sc1.TargetPath = '%EXE_PATH%'; " ^
    "$sc1.WorkingDirectory = '%TARGET_DIR%'; " ^
    "$sc1.IconLocation = '%ICON_PATH%,0'; " ^
    "$sc1.Description = 'Nave - O Navegador Desktop da OZATI'; " ^
    "$sc1.Save(); " ^
    "$sc2 = $ws.CreateShortcut((Join-Path $startMenu 'Nave.lnk')); " ^
    "$sc2.TargetPath = '%EXE_PATH%'; " ^
    "$sc2.WorkingDirectory = '%TARGET_DIR%'; " ^
    "$sc2.IconLocation = '%ICON_PATH%,0'; " ^
    "$sc2.Description = 'Nave - O Navegador Desktop da OZATI'; " ^
    "$sc2.Save(); " ^
    "Write-Host 'Atalhos criados com sucesso na Area de Trabalho e no Menu Iniciar!' -ForegroundColor Green"

echo.
echo Pronto! O icone oficial do Nave ja esta no seu sistema.
echo.
ping -n 3 127.0.0.1 >nul
exit /b 0
