# ============================================================
# Phase 1 : Fix topologie + Ajout pfSense VMware
# ============================================================

$GNS3_URL = "http://localhost:3080/v2"
$PROJECT_ID = "cb731528-de8c-488a-bb1b-65c6813541a7"
$BASE = "$GNS3_URL/projects/$PROJECT_ID"

# --- Node IDs (from audit) ---
$SWITCH_ID   = "52df1e27-8212-49cf-8e67-1ca5cf74bd53"
$RD_LAB2_ID  = "64fdacb8-6c47-4bc7-8b2b-6f110eb94047"
$ADMIN_ID    = "ac9fcf89-d083-44b9-8279-c7088cc338a2"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Phase 1 : Fix Topologie + pfSense" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================
# ETAPE 1.1 : Arrêter les VPCS problématiques avant de recâbler
# ============================================================
Write-Host ""
Write-Host "[1.1] Arret des noeuds pour recablage..." -ForegroundColor Magenta

try {
    Invoke-RestMethod -Uri "$BASE/nodes/$RD_LAB2_ID/stop" -Method POST -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Write-Host "  [OK] PC-RD-LAB2 arrete" -ForegroundColor Green
} catch { Write-Host "  [!] PC-RD-LAB2 deja arrete ou erreur" -ForegroundColor Yellow }

try {
    Invoke-RestMethod -Uri "$BASE/nodes/$ADMIN_ID/stop" -Method POST -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Write-Host "  [OK] PC-ADMIN-MGMT arrete" -ForegroundColor Green
} catch { Write-Host "  [!] PC-ADMIN-MGMT deja arrete ou erreur" -ForegroundColor Yellow }

Start-Sleep -Seconds 2

# ============================================================
# ETAPE 1.2 : Recréer les 2 liens cassés
# ============================================================
Write-Host ""
Write-Host "[1.2] Recreation des liens casses..." -ForegroundColor Magenta

# Lien PC-RD-LAB2 <-> Switch Port 6 (VLAN 30)
$linkBody1 = @{
    nodes = @(
        @{ node_id = $RD_LAB2_ID;  adapter_number = 0; port_number = 0 }
        @{ node_id = $SWITCH_ID;   adapter_number = 0; port_number = 6 }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$BASE/links" -Method POST -Body $linkBody1 -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Write-Host "  [OK] Lien PC-RD-LAB2 <-> SW Port 6 (VLAN 30) cree !" -ForegroundColor Green
} catch {
    Write-Host "  [!] Erreur lien PC-RD-LAB2: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 1

# Lien PC-ADMIN-MGMT <-> Switch Port 7 (VLAN 100)
$linkBody2 = @{
    nodes = @(
        @{ node_id = $ADMIN_ID;    adapter_number = 0; port_number = 0 }
        @{ node_id = $SWITCH_ID;   adapter_number = 0; port_number = 7 }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$BASE/links" -Method POST -Body $linkBody2 -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Write-Host "  [OK] Lien PC-ADMIN-MGMT <-> SW Port 7 (VLAN 100) cree !" -ForegroundColor Green
} catch {
    Write-Host "  [!] Erreur lien PC-ADMIN-MGMT: $($_.Exception.Message)" -ForegroundColor Red
}

# Redémarrer les VPCS
Start-Sleep -Seconds 1
try {
    Invoke-RestMethod -Uri "$BASE/nodes/$RD_LAB2_ID/start" -Method POST -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Invoke-RestMethod -Uri "$BASE/nodes/$ADMIN_ID/start" -Method POST -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Write-Host "  [OK] VPCS redemarres" -ForegroundColor Green
} catch { Write-Host "  [!] Erreur redemarrage: $($_.Exception.Message)" -ForegroundColor Yellow }

# ============================================================
# ETAPE 1.3 : Créer le template VMware pour pfSense
# ============================================================
Write-Host ""
Write-Host "[1.3] Creation du template VMware pfSense..." -ForegroundColor Magenta

$pfSenseTemplate = @{
    name              = "pfSense-Firewall"
    template_type     = "vmware"
    compute_id        = "local"
    vmx_path          = "D:\VM\PfSense.vmx"
    linked_clone      = $false
    headless          = $false
    on_close          = "save_vm_state"
    adapters          = 2
    adapter_type      = "e1000"
    use_any_adapter   = $true
    category          = "firewall"
    symbol            = ":/symbols/firewall.svg"
    default_name_format = "pfSense-{0}"
} | ConvertTo-Json -Depth 3

try {
    $templateResult = Invoke-RestMethod -Uri "$GNS3_URL/templates" -Method POST -Body $pfSenseTemplate -ContentType "application/json" -TimeoutSec 10
    $PFSENSE_TEMPLATE_ID = $templateResult.template_id
    Write-Host "  [OK] Template pfSense cree (ID: $PFSENSE_TEMPLATE_ID)" -ForegroundColor Green
} catch {
    Write-Host "  [!] Erreur template: $($_.Exception.Message)" -ForegroundColor Red
    # Essayer de récupérer le template existant
    $templates = Invoke-RestMethod -Uri "$GNS3_URL/templates" -TimeoutSec 10
    $existing = $templates | Where-Object { $_.name -eq "pfSense-Firewall" }
    if ($existing) {
        $PFSENSE_TEMPLATE_ID = $existing.template_id
        Write-Host "  [OK] Template existant trouve: $PFSENSE_TEMPLATE_ID" -ForegroundColor Yellow
    }
}

# ============================================================
# ETAPE 1.4 : Créer le noeud pfSense dans le projet
# ============================================================
Write-Host ""
Write-Host "[1.4] Ajout du noeud pfSense au projet..." -ForegroundColor Magenta

if ($PFSENSE_TEMPLATE_ID) {
    $pfSenseNode = @{
        x = 0
        y = -300
    } | ConvertTo-Json

    try {
        $pfResult = Invoke-RestMethod -Uri "$BASE/templates/$PFSENSE_TEMPLATE_ID" -Method POST -Body $pfSenseNode -ContentType "application/json" -TimeoutSec 30
        $PFSENSE_NODE_ID = $pfResult.node_id
        Write-Host "  [OK] pfSense ajoute au projet (ID: $PFSENSE_NODE_ID)" -ForegroundColor Green
        
        # Sauvegarder l'ID pour les scripts suivants
        $PFSENSE_NODE_ID | Out-File -FilePath "C:\Users\Administrateur\Desktop\Cours\B3\Fil_Rouge\infrastructure\reseau\pfsense_node_id.txt"
        
    } catch {
        Write-Host "  [!] Erreur ajout pfSense: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  [!] Pas de template pfSense disponible, impossible d'ajouter le noeud" -ForegroundColor Red
}

# ============================================================
# ETAPE 1.5 : Câbler pfSense
# ============================================================
Write-Host ""
Write-Host "[1.5] Cablage de pfSense..." -ForegroundColor Magenta

if ($PFSENSE_NODE_ID) {
    # pfSense eth1 (LAN/Trunk) <-> Switch Port 0 (Trunk)
    $linkPfSwitch = @{
        nodes = @(
            @{ node_id = $PFSENSE_NODE_ID; adapter_number = 1; port_number = 0 }
            @{ node_id = $SWITCH_ID;       adapter_number = 0; port_number = 0 }
        )
    } | ConvertTo-Json -Depth 5

    try {
        Invoke-RestMethod -Uri "$BASE/links" -Method POST -Body $linkPfSwitch -ContentType "application/json" -TimeoutSec 10 | Out-Null
        Write-Host "  [OK] pfSense LAN (eth1) <-> SW-CORE Trunk (Port 0) cree !" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Erreur lien pfSense-Switch: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  [INFO] pfSense WAN (eth0) = VMware NAT (Internet automatique)" -ForegroundColor Cyan
    Write-Host "  [INFO] pfSense LAN (eth1) = Trunk vers SW-CORE-BIOTECH" -ForegroundColor Cyan
} else {
    Write-Host "  [!] Pas de noeud pfSense, cablage impossible" -ForegroundColor Red
}

# ============================================================
# RÉSUMÉ Phase 1
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " PHASE 1 TERMINEE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérification finale
$allNodes = Invoke-RestMethod -Uri "$BASE/nodes" -TimeoutSec 10
$allLinks = Invoke-RestMethod -Uri "$BASE/links" -TimeoutSec 10
Write-Host " Noeuds: $($allNodes.Count)" -ForegroundColor White
Write-Host " Liens:  $($allLinks.Count)" -ForegroundColor White
foreach ($n in $allNodes) {
    Write-Host "  - $($n.name) [$($n.node_type)] = $($n.status)" -ForegroundColor Gray
}
