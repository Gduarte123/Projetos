@echo off
chcp 65001 >nul

echo =====================================================
echo   COLETOR DE INVENTARIO - WINDOWS
echo   ADICIONA LINHA NO Inventario.xlsx
echo =====================================================
echo.

:: Verifica se o módulo ImportExcel está instalado
powershell -NoProfile -Command ^
  "if (-not (Get-Module -ListAvailable -Name ImportExcel)) { Install-Module ImportExcel -Force -Scope CurrentUser }"

echo.
echo Coletando informacoes e atualizando planilha...
echo.

:: Executa o PowerShell
powershell -NoProfile -Command ^

  "Import-Module ImportExcel;" ^

  "$Comp = Get-CimInstance Win32_ComputerSystem;" ^
  "$OS = Get-CimInstance Win32_OperatingSystem;" ^
  "$BIOS = Get-CimInstance Win32_BIOS;" ^
  "$CPU = Get-CimInstance Win32_Processor;" ^
  "$GPU = Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue -First 1;" ^
  "$Disk = Get-PhysicalDisk;" ^
  "$DiskLogical = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3';" ^

  "$User = $Comp.UserName;" ^
  "$PC = $Comp.Name;" ^

  "$NetAdapt = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -eq $true } | Select-Object -First 1;" ^
  "$MAC = $NetAdapt.MacAddress;" ^
  "$IPv4Info = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceIndex -eq $NetAdapt.ifIndex -and $_.IPAddress -notlike '169.*' } | Select-Object -First 1;" ^
  "$IP = $IPv4Info.IPAddress;" ^
  "$GatewayInfo = Get-NetIPConfiguration | Where-Object { $_.InterfaceIndex -eq $NetAdapt.ifIndex };" ^
  "$Gateway = $GatewayInfo.IPv4DefaultGateway.NextHop;" ^
  "$DNS = ($GatewayInfo.DnsServer.ServerAddresses -join ', ');" ^

  "$RAMSticks = (Get-CimInstance Win32_PhysicalMemory | ForEach-Object { ($_.Manufacturer + ' ' + $_.PartNumber).Trim() }) -join '; ';" ^ ^
  "$RAMTotal = [math]::Round($Comp.TotalPhysicalMemory / 1GB,2);" ^
  "$RAMFree = [math]::Round($OS.FreePhysicalMemory / 1MB,2);" ^

  "$DiskModel = ($Disk | Select-Object -ExpandProperty FriendlyName -ErrorAction SilentlyContinue) -join '; ';" ^
  "$DiskTotal = [math]::Round(($DiskLogical.Size | Measure-Object -Sum).Sum / 1GB,2);" ^
  "$DiskFree = [math]::Round(($DiskLogical.FreeSpace | Measure-Object -Sum).Sum / 1GB,2);" ^

  "$Data = [PSCustomObject]@{" ^
    'Data/Hora'        = (Get-Date -Format 'dd/MM/yyyy HH:mm'); ^
    'Nome do PC'       = $Comp.Name; ^
    'Usuario Logado'   = $User; ^
    'Fabricante'       = $Comp.Manufacturer; ^
    'Modelo do PC'     = $Comp.Model; ^
    'Numero de Serie'  = $BIOS.SerialNumber; ^
    'BIOS/UEFI'        = $BIOS.SMBIOSBIOSVersion; ^
    'Windows'          = $OS.Caption; ^
    'Build'            = $OS.BuildNumber; ^
    'Arquitetura'      = $OS.OSArchitecture; ^
    'CPU'              = $CPU.Name; ^
    'Nucleos'          = $CPU.NumberOfCores; ^
    'Threads'          = $CPU.NumberOfLogicalProcessors; ^
    'RAM Total (GB)'   = $RAMTotal; ^
    'RAM Livre (GB)'   = $RAMFree; ^
    'Modelo da RAM'    = $RAMSticks; ^
    'Modelo do Disco'  = $DiskModel; ^
    'Disco Total (GB)' = $DiskTotal; ^
    'Disco Livre (GB)' = $DiskFree; ^
    'GPU'              = $GPU; ^
    'IP'               = $IP; ^
    'MAC'              = $MAC; ^
    'Gateway'          = $Gateway; ^
    'DNS'              = $DNS ^
  "};" ^

  "$Path = Join-Path (Get-Location) 'Inventario.xlsx';" ^
  "if (Test-Path $Path) { $Data | Export-Excel -Path $Path -WorksheetName 'Inventario' -AutoSize -Append }" ^
  "else { $Data | Export-Excel -Path $Path -WorksheetName 'Inventario' -AutoSize }" ^
  "Write-Host 'Inventario atualizado em: ' $Path -ForegroundColor Green"

echo.
echo ✔ PROCESSO CONCLUIDO! Linha adicionada em Inventario.xlsx.
echo Pressione qualquer tecla para sair...
pause >nul
