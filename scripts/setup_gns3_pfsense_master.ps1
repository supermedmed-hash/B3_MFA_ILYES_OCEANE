# ==============================================================================
# 🎛️ SCRIPT ONE-SHOT CONFIGURATION GNS3 & PFSENSE - SMART OFFICE 2.0
# ==============================================================================
# Ce script configure d'un coup l'environnement local :
#   1. Répare la topologie GNS3, câble le pfSense et démarre le pare-feu.
#   2. Configure les adresses IP et routes de tous les postes clients (VPCS).
#   3. Détecte votre IP publique et pousse la configuration IPsec/VLAN/DHCP/Firewall sur pfSense.
#
# USAGE :
#   .\scripts\setup_gns3_pfsense_master.ps1 -AzureVpnIP "20.19.2.95"
# ==============================================================================

param(
    [string]$AzureVpnIP = "",          # L'IP publique du VPN Azure (obtenue après le déploiement Azure)
    [string]$PfSenseIP = "192.168.2.145" # L'IP LAN/WAN d'administration de pfSense
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🎛️ CONFIGURATION ONE-SHOT LOCAL (GNS3 & PFSENSE)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 0. Vérification des Prérequis
# ============================================================
Write-Host "[0] Vérification des prérequis système..." -ForegroundColor Magenta

# A. Vérifier si GNS3 API est en ligne
Write-Host "  🔍 Vérification de GNS3 API..." -ForegroundColor Yellow
try {
    $gns3Test = Invoke-RestMethod -Uri "http://localhost:3080/v2/version" -TimeoutSec 3
    Write-Host "  [OK] GNS3 API en ligne (version: $($gns3Test.version))" -ForegroundColor Green
} catch {
    Write-Error "GNS3 n'est pas démarré ou n'écoute pas sur http://localhost:3080. Lancez GNS3 d'abord."
}

# B. Vérifier si le fichier VM pfSense existe
Write-Host "  🔍 Vérification du fichier VM pfSense..." -ForegroundColor Yellow
if (-not (Test-Path "D:\VM\PfSense.vmx")) {
    Write-Error "Le fichier VM pfSense n'a pas été trouvé à l'emplacement prévu : D:\VM\PfSense.vmx. Veuillez ajuster le chemin dans 'infrastructure/reseau/fix_and_complete_topology.ps1' et ce script."
}
Write-Host "  [OK] Fichier VM pfSense trouvé." -ForegroundColor Green

# C. Vérifier si Python est installé
Write-Host "  🔍 Vérification de Python..." -ForegroundColor Yellow
$pythonTest = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonTest) {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3."
}
Write-Host "  [OK] Python détecté." -ForegroundColor Green

# D. Vérifier si Paramiko est installé
Write-Host "  🔍 Vérification de la bibliothèque Python 'paramiko'..." -ForegroundColor Yellow
$paramikoTest = python -c "import paramiko; print('OK')" 2>$null
if ($paramikoTest -ne "OK") {
    Write-Error "La bibliothèque Python 'paramiko' n'est pas installée. Veuillez l'installer avec 'pip install paramiko'."
}
Write-Host "  [OK] Paramiko détecté." -ForegroundColor Green

Write-Host "  [OK] Tous les prérequis sont validés !" -ForegroundColor Green
Write-Host ""

# ============================================================
# 1. Réparation & Configuration de la Topologie GNS3
# ============================================================
Write-Host "[1] Configuration et câblage de la topologie GNS3..." -ForegroundColor Magenta
if (-not (Test-Path "infrastructure/reseau/fix_and_complete_topology.ps1")) {
    Write-Error "Script 'fix_and_complete_topology.ps1' introuvable."
}
& "infrastructure/reseau/fix_and_complete_topology.ps1"

# Démarrer le nœud pfSense via l'API GNS3
Write-Host "  Démarrage du nœud pfSense dans GNS3..." -ForegroundColor Yellow
$GNS3_URL = "http://localhost:3080/v2"
$PROJECT_ID = "cb731528-de8c-488a-bb1b-65c6813541a7"
$BASE = "$GNS3_URL/projects/$PROJECT_ID"
$PFSENSE_NODE_ID = Get-Content -Path "infrastructure/reseau/pfsense_node_id.txt" -Raw -ErrorAction SilentlyContinue

if ($PFSENSE_NODE_ID) {
    try {
        Invoke-RestMethod -Uri "$BASE/nodes/$($PFSENSE_NODE_ID.Trim())/start" -Method POST -ContentType "application/json" -TimeoutSec 10 | Out-Null
        Write-Host "  [OK] pfSense démarré avec succès !" -ForegroundColor Green
    } catch {
        Write-Host "  [!] pfSense déjà démarré ou erreur de démarrage : $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Warning "ID du pfSense introuvable dans pfsense_node_id.txt. Assurez-vous que pfSense est démarré dans GNS3."
}

# ============================================================
# 2. Configuration des VPCS (Postes de travail)
# ============================================================
Write-Host ""
Write-Host "[2] Configuration des adresses IP des VPCS (via Telnet)..." -ForegroundColor Magenta
Write-Host "    Attente de 5s pour s'assurer que les consoles VPCS sont prêtes..." -ForegroundColor Gray
Start-Sleep -Seconds 5

if (-not (Test-Path "infrastructure/reseau/configure_vpcs.ps1")) {
    Write-Error "Script 'configure_vpcs.ps1' introuvable."
}
& "infrastructure/reseau/configure_vpcs.ps1"

# ============================================================
# 3. Pousser la Configuration Réseau & IPsec sur pfSense
# ============================================================
Write-Host ""
Write-Host "[3] Configuration et sécurité de pfSense..." -ForegroundColor Magenta

# Détection de l'IP publique de l'hôte
Write-Host "  Détection de votre IP publique actuelle..." -ForegroundColor Yellow
$MyPublicIP = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
Write-Host "  IP Publique On-Premise détectée : $MyPublicIP" -ForegroundColor Green

# Demande de l'IP du VPN Azure si vide
if (-not $AzureVpnIP) {
    Write-Host ""
    $AzureVpnIP = Read-Host "Entrez l'IP publique du VPN Azure (laisser vide pour garder l'existante)"
    if (-not $AzureVpnIP) {
        $AzureVpnIP = "20.19.2.95" # Fallback valeur existante
        Write-Host "  -> Utilisation de la valeur existante : $AzureVpnIP" -ForegroundColor Gray
    }
}

# Mettre à jour dynamiquement le script Python pfsense_ssh_config.py avant de le lancer
Write-Host "  Génération et exécution de la configuration pfSense via Python SSH..." -ForegroundColor Yellow
$pyPath = "scripts/pfsense_ssh_config.py"
if (Test-Path $pyPath) {
    $content = Get-Content -Path $pyPath -Raw
    
    # Remplacer les valeurs d'IP dans le script python
    $content = $content -replace '"remote-gateway" => ".*?"', ("`"remote-gateway`" => `"$AzureVpnIP`"")
    $content = $content -replace '"myid_data" => ".*?"', ("`"myid_data`" => `"$MyPublicIP`"")
    $content = $content -replace '"peerid_data" => ".*?"', ("`"peerid_data`" => `"$AzureVpnIP`"")
    $content = $content -replace 'client\.connect\(".*?",', ("client.connect(`"$PfSenseIP`",")
    
    $content | Out-File -FilePath $pyPath -Encoding utf8 -Force
    
    # Exécuter le script
    python $pyPath
} else {
    Write-Error "Fichier 'scripts/pfsense_ssh_config.py' introuvable."
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🎉 ENVIRONNEMENT GNS3 & PFSENSE CONFIGURÉ EN ONE-SHOT !" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
