# ============================================================
# Phase 2 : Configuration IP de tous les VPCS
# ============================================================
# Se connecte en Telnet à chaque VPCS et configure l'IP

$GNS3_URL = "http://localhost:3080/v2"
$PROJECT_ID = "cb731528-de8c-488a-bb1b-65c6813541a7"
$BASE = "$GNS3_URL/projects/$PROJECT_ID"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Phase 2 : Configuration IP des VPCS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Récupérer tous les noeuds avec leurs ports console
$nodes = Invoke-RestMethod -Uri "$BASE/nodes" -TimeoutSec 10

# Table de configuration : nom -> IP/masque/gateway
$vpcsConfig = @{
    "AD-SRV-2019"    = @{ ip = "10.10.10.10";  mask = "24"; gw = "10.10.10.254" }
    "SQL-SRV"        = @{ ip = "10.10.10.20";  mask = "24"; gw = "10.10.10.254" }
    "PC-EMPLOYEE-1"  = @{ ip = "10.10.20.50";  mask = "24"; gw = "10.10.20.254" }
    "PC-EMPLOYEE-2"  = @{ ip = "10.10.20.51";  mask = "24"; gw = "10.10.20.254" }
    "PC-RD-LAB1"     = @{ ip = "10.10.30.50";  mask = "24"; gw = "10.10.30.254" }
    "PC-RD-LAB2"     = @{ ip = "10.10.30.51";  mask = "24"; gw = "10.10.30.254" }
    "PC-ADMIN-MGMT"  = @{ ip = "10.10.100.10"; mask = "24"; gw = "10.10.100.254" }
}

# Fonction pour envoyer des commandes via Telnet
function Send-TelnetCommand {
    param(
        [string]$Host_,
        [int]$Port,
        [string[]]$Commands,
        [int]$DelayMs = 500
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Host_, $Port)
        $stream = $tcpClient.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $reader = New-Object System.IO.StreamReader($stream)
        $writer.AutoFlush = $true

        Start-Sleep -Milliseconds $DelayMs

        # Lire le banner initial
        if ($stream.DataAvailable) {
            $buffer = New-Object byte[] 4096
            $read = $stream.Read($buffer, 0, $buffer.Length)
        }

        foreach ($cmd in $Commands) {
            $writer.WriteLine($cmd)
            Start-Sleep -Milliseconds $DelayMs

            # Lire la réponse
            if ($stream.DataAvailable) {
                $buffer = New-Object byte[] 4096
                $read = $stream.Read($buffer, 0, $buffer.Length)
                $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $read)
            }
        }

        $tcpClient.Close()
        return $true
    }
    catch {
        Write-Host "    [!] Erreur Telnet: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Configurer chaque VPCS
foreach ($node in $nodes) {
    if ($node.node_type -ne "vpcs") { continue }

    $config = $vpcsConfig[$node.name]
    if (-not $config) { continue }

    $consolePort = $node.console
    $ip = $config.ip
    $mask = $config.mask
    $gw = $config.gw

    Write-Host ""
    Write-Host "  Configuring $($node.name) (console: $consolePort)..." -ForegroundColor Yellow
    Write-Host "    IP: $ip/$mask  GW: $gw" -ForegroundColor Gray

    $commands = @(
        ""  # wake up console
        "ip $ip/$mask $gw"
        "save"
    )

    $success = Send-TelnetCommand -Host_ "127.0.0.1" -Port $consolePort -Commands $commands -DelayMs 800

    if ($success) {
        Write-Host "    [OK] $($node.name) configure: $ip/$mask gw $gw" -ForegroundColor Green
    } else {
        Write-Host "    [FAIL] Impossible de configurer $($node.name)" -ForegroundColor Red
    }
}

# ============================================================
# Vérification : Lire les configs
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Verification des configurations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($node in $nodes) {
    if ($node.node_type -ne "vpcs") { continue }

    $consolePort = $node.console

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("127.0.0.1", $consolePort)
        $stream = $tcpClient.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $reader = New-Object System.IO.StreamReader($stream)
        $writer.AutoFlush = $true

        Start-Sleep -Milliseconds 500
        # Clear buffer
        if ($stream.DataAvailable) {
            $buffer = New-Object byte[] 4096
            $stream.Read($buffer, 0, $buffer.Length) | Out-Null
        }

        $writer.WriteLine("show ip")
        Start-Sleep -Milliseconds 800

        if ($stream.DataAvailable) {
            $buffer = New-Object byte[] 4096
            $read = $stream.Read($buffer, 0, $buffer.Length)
            $response = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $read)
            $ipLine = ($response -split "`n" | Where-Object { $_ -match "IP|CIDR|GW" }) -join " | "
            Write-Host "  $($node.name): $ipLine" -ForegroundColor Gray
        }

        $tcpClient.Close()
    }
    catch {
        Write-Host "  $($node.name): Erreur lecture config" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " PHASE 2 TERMINEE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
