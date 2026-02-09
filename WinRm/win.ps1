# ================================
# CONFIGURACAO DEFINITIVA DO WINRM
# COMPATIVEL PT-BR / EN-US
# SEM WMIC
# PERSISTENTE APOS REBOOT
# ================================

$User  = "winrmuser"
$Pass  = "S3nh@1995"
$Port  = 5985

Write-Host "=== INICIANDO CONFIGURACAO DEFINITIVA DO WINRM ===" -ForegroundColor Cyan

# ---------- GARANTE EXECUCAO COMO ADMIN ----------
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Execute este script como ADMINISTRADOR."
    exit 1
}

# ---------- CRIA USUARIO SE NAO EXISTIR ----------
if (-not (Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {
    $SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force
    New-LocalUser `
        -Name $User `
        -Password $SecurePass `
        -PasswordNeverExpires `
        -UserMayNotChangePassword `
        -AccountNeverExpires
}

# ---------- DESCOBRE GRUPO ADMIN (PT/EN) ----------
$AdminGroup = Get-LocalGroup | Where-Object {
    $_.Name -in @("Administradores", "Administrators")
}

# ---------- ADICIONA USUARIO AO GRUPO ADMIN ----------
if (-not (Get-LocalGroupMember $AdminGroup.Name | Where-Object Name -like "*\$User")) {
    Add-LocalGroupMember -Group $AdminGroup.Name -Member $User
}

# ---------- HABILITA WINRM ----------
winrm quickconfig -q

# ---------- CONFIGURACOES DO SERVICO ----------
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# ---------- CONFIGURACOES DO CLIENT ----------
winrm set winrm/config/client '@{TrustedHosts="*"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

# ---------- GARANTE LISTENER HTTP ----------
$listener = winrm enumerate winrm/config/listener | Select-String "Transport = HTTP"
if (-not $listener) {
    winrm create winrm/config/listener?Address=*+Transport=HTTP
}

# ---------- FIREWALL ----------
if (-not (Get-NetFirewallRule -DisplayName "WINRM-HTTP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "WINRM-HTTP" `
        -DisplayName "WINRM-HTTP" `
        -Protocol TCP `
        -LocalPort $Port `
        -Direction Inbound `
        -Action Allow `
        -Profile Any
}

# ---------- TOKEN FILTER (CRITICO PARA CREDENCIAIS LOCAIS) ----------
New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "LocalAccountTokenFilterPolicy" `
    -Value 1 `
    -PropertyType DWord `
    -Force | Out-Null

# ---------- GARANTE SERVICO AUTOMATICO ----------
Set-Service WinRM -StartupType Automatic
Restart-Service WinRM

# ---------- TESTE LOCAL ----------
Write-Host ""
Write-Host "=== TESTE LOCAL ===" -ForegroundColor Yellow
whoami
winrm enumerate winrm/config/listener

# ---------- FINAL ----------
Write-Host ""
Write-Host "WINRM CONFIGURADO DEFINITIVAMENTE" -ForegroundColor Green
Write-Host "Usuario: $User"
Write-Host "Senha: $Pass"
Write-Host "Porta: $Port"
Write-Host "Basic Auth: ATIVO"
Write-Host "Persistente apos reboot"
Write-Host ""
Pause

