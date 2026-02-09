# =====================================================
# CartorioHealth - Health Check & Self-Healing
# Execucao: SYSTEM | Invisivel ao usuario
# =====================================================

# ---------------- CONFIGURACOES ----------------
$BasePath      = "C:\ProgramData\CartorioHealth"
$LogPath       = Join-Path $BasePath "Logs"
$TodayLog      = Join-Path $LogPath ("{0}.log" -f (Get-Date -Format "yyyy-MM-dd"))
$RetentionDays = 30

$ErroCritico = $false

# ---------------- INICIALIZACAO ----------------
foreach ($path in @($BasePath, $LogPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# ---------------- FUNCAO DE LOG ----------------
function Write-Log {
    param (
        [string]$Categoria,
        [string]$Mensagem
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $TodayLog -Value "$Timestamp | $Categoria | $Mensagem"
}

Write-Log "INICIO" "Health Check iniciado"

# ---------------- LIMPEZA DE LOGS ANTIGOS ----------------
Get-ChildItem $LogPath -Filter "*.log" -ErrorAction SilentlyContinue |
Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
Remove-Item -Force -ErrorAction SilentlyContinue

# ---------------- CHECAGEM DE REDE ----------------
try {
    $net = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway }

    if ($net -and $net.IPv4Address.IPAddress) {
        Write-Log "REDE" "IP obtido automaticamente (OK)"
    }

    if ($net -and (Test-Connection $net.IPv4DefaultGateway.NextHop -Count 1 -Quiet)) {
        Write-Log "REDE" "Gateway alcancavel (OK)"
    } else {
        Write-Log "REDE" "Gateway inacessivel"
        $ErroCritico = $true
    }

    if (Resolve-DnsName "google.com" -ErrorAction SilentlyContinue) {
        Write-Log "DNS" "Resolucao DNS funcionando (OK)"
    } else {
        Write-Log "DNS" "Falha na resolucao DNS"
        $ErroCritico = $true
    }
}
catch {
    Write-Log "REDE" "Erro ao validar configuracoes de rede"
    $ErroCritico = $true
}

# ---------------- DATA E HORA ----------------
try {
    w32tm /resync /nowait | Out-Null
    Write-Log "HORA" "Data e hora sincronizadas (OK)"
}
catch {
    Write-Log "HORA" "Falha ao sincronizar data e hora"
    $ErroCritico = $true
}

# ---------------- SERVICO DE IMPRESSAO ----------------
try {
    $spooler = Get-Service -Name Spooler -ErrorAction Stop

    if ($spooler.Status -eq "Running") {
        Restart-Service Spooler -Force
        Write-Log "PRINT" "Spooler reiniciado preventivamente"
    }
    else {
        Start-Service Spooler
        Write-Log "PRINT" "Spooler estava parado - iniciado"
    }
}
catch {
    Write-Log "PRINT" "Erro ao controlar o Spooler"
    $ErroCritico = $true
}

# ---------------- DRIVERS DE IMPRESSAO ----------------
try {
    $drivers = Get-PrinterDriver -ErrorAction SilentlyContinue

    if ($drivers -and $drivers.Count -gt 0) {
        Write-Log "DRIVER" "Drivers de impressora carregados (OK)"
    }
    else {
        Write-Log "DRIVER" "Nenhum driver de impressora encontrado"
        $ErroCritico = $true
    }
}
catch {
    Write-Log "DRIVER" "Erro ao verificar drivers"
    $ErroCritico = $true
}

# ---------------- SFC CONDICIONAL ----------------
if ($ErroCritico) {
    try {
        Write-Log "SFC" "Erro critico detectado - iniciando SFC"
        sfc /scannow | Out-Null
        Write-Log "SFC" "SFC finalizado"
    }
    catch {
        Write-Log "SFC" "Erro ao executar SFC"
    }
}
else {
    Write-Log "SFC" "Nenhum erro critico - SFC nao necessario"
}

Write-Log "FIM" "Health Check finalizado"
