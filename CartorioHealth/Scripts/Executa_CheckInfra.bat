@echo off
REM ==========================================
REM CartorioHealth - Launcher BAT (Diretório atual)
REM ==========================================

REM Obtém o diretório onde o BAT está
set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%CheckInfra.ps1

REM Verifica se o script existe
if not exist "%PS_SCRIPT%" (
    echo ERRO: CheckInfra.ps1 nao encontrado no diretorio:
    echo %SCRIPT_DIR%
    exit /b 1
)

REM Executa o PowerShell ignorando policy e perfil
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

exit /b 0
