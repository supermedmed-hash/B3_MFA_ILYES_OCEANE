# ============================================================
# Script : Setup GNS3 Topology - Smart Office 2.0
# Description : Crée automatiquement la topologie réseau
#               via l'API REST GNS3 (Built-in, sans licence)
# ============================================================

$GNS3_URL = "http://localhost:3080/v2"
$PROJECT_ID = "cb731528-de8c-488a-bb1b-65c6813541a7"
$BASE = "$GNS3_URL/projects/$PROJECT_ID"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Smart Office 2.0 - GNS3 Topology Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Fonction helper pour créer un noeud ---
function New-GNS3Node {
    param(
        [string]$Name,
        [string]$NodeType,
        [int]$X,
        [int]$Y,
        [hashtable]$Properties = @{},
        [string]$Symbol = "",
        [string]$ComputeId = "local"
    )

    $body = @{
        name       = $Name
        node_type  = $NodeType
        compute_id = $ComputeId
        x          = $X
        y          = $Y
    }

    if ($Properties.Count -gt 0) {
        $body["properties"] = $Properties
    }
    if ($Symbol -ne "") {
        $body["symbol"] = $Symbol
    }

    $json = $body | ConvertTo-Json -Depth 5
    $result = Invoke-RestMethod -Uri "$BASE/nodes" -Method POST -Body $json -ContentType "application/json" -TimeoutSec 10
    Write-Host "  [+] Node cree: $Name (ID: $($result.node_id))" -ForegroundColor Green
    return $result
}

# --- Fonction helper pour créer un lien ---
function New-GNS3Link {
    param(
        [string]$NodeId1,
        [int]$Adapter1,
        [int]$Port1,
        [string]$NodeId2,
        [int]$Adapter2,
        [int]$Port2
    )

    $body = @{
        nodes = @(
            @{
                node_id      = $NodeId1
                adapter_number = $Adapter1
                port_number    = $Port1
            },
            @{
                node_id      = $NodeId2
                adapter_number = $Adapter2
                port_number    = $Port2
            }
        )
    }

    $json = $body | ConvertTo-Json -Depth 5
    $result = Invoke-RestMethod -Uri "$BASE/links" -Method POST -Body $json -ContentType "application/json" -TimeoutSec 10
    Write-Host "  [~] Lien cree entre les noeuds" -ForegroundColor Yellow
    return $result
}

# ============================================================
# ETAPE 1 : Créer le Switch Core avec les VLANs
# ============================================================
Write-Host ""
Write-Host "[ETAPE 1] Creation du Switch Core (SW-CORE-BIOTECH)..." -ForegroundColor Magenta

# Le switch Ethernet built-in supporte les VLANs via ses propriétés "ports_mapping"
$switchProperties = @{
    ports_mapping = @(
        # Port 0 : Trunk vers pfSense (toutes les VLANs)
        @{ name = "Trunk-pfSense"; port_number = 0; type = "dot1q"; vlan = 1; ethertype = "0x8100" }
        # Port 1 : VLAN 10 - SERVERS (Access)
        @{ name = "VLAN10-SRV";    port_number = 1; type = "access"; vlan = 10 }
        # Port 2 : VLAN 10 - SERVERS (Access) - 2ème port serveur
        @{ name = "VLAN10-SRV2";   port_number = 2; type = "access"; vlan = 10 }
        # Port 3 : VLAN 20 - EMPLOYEES (Access)
        @{ name = "VLAN20-EMP1";   port_number = 3; type = "access"; vlan = 20 }
        # Port 4 : VLAN 20 - EMPLOYEES (Access)
        @{ name = "VLAN20-EMP2";   port_number = 4; type = "access"; vlan = 20 }
        # Port 5 : VLAN 30 - R&D (Access)
        @{ name = "VLAN30-RD1";    port_number = 5; type = "access"; vlan = 30 }
        # Port 6 : VLAN 30 - R&D (Access)
        @{ name = "VLAN30-RD2";    port_number = 6; type = "access"; vlan = 30 }
        # Port 7 : VLAN 100 - MANAGEMENT (Access)
        @{ name = "VLAN100-MGMT";  port_number = 7; type = "access"; vlan = 100 }
    )
}

$switch = New-GNS3Node -Name "SW-CORE-BIOTECH" -NodeType "ethernet_switch" -X 0 -Y 0 -Properties $switchProperties

# ============================================================
# ETAPE 2 : Créer les postes clients (VPCS)
# ============================================================
Write-Host ""
Write-Host "[ETAPE 2] Creation des postes clients (VPCS)..." -ForegroundColor Magenta

# VLAN 10 - Serveurs
$adServer = New-GNS3Node -Name "AD-SRV-2019" -NodeType "vpcs" -X -300 -Y -200
$sqlServer = New-GNS3Node -Name "SQL-SRV" -NodeType "vpcs" -X -300 -Y -100

# VLAN 20 - Employees
$pcEmp1 = New-GNS3Node -Name "PC-EMPLOYEE-1" -NodeType "vpcs" -X -300 -Y 100
$pcEmp2 = New-GNS3Node -Name "PC-EMPLOYEE-2" -NodeType "vpcs" -X -300 -Y 200

# VLAN 30 - R&D
$pcRd1 = New-GNS3Node -Name "PC-RD-LAB1" -NodeType "vpcs" -X 300 -Y 100
$pcRd2 = New-GNS3Node -Name "PC-RD-LAB2" -NodeType "vpcs" -X 300 -Y 200

# VLAN 100 - Management
$pcMgmt = New-GNS3Node -Name "PC-ADMIN-MGMT" -NodeType "vpcs" -X 300 -Y -200

# ============================================================
# ETAPE 3 : Créer le noeud NAT (simule la sortie Internet / futur pfSense)
# ============================================================
Write-Host ""
Write-Host "[ETAPE 3] Creation du noeud NAT (sortie Internet)..." -ForegroundColor Magenta

$nat = New-GNS3Node -Name "INTERNET-GW" -NodeType "nat" -X 0 -Y -350

# ============================================================
# ETAPE 4 : Câblage de la topologie
# ============================================================
Write-Host ""
Write-Host "[ETAPE 4] Cablage de la topologie..." -ForegroundColor Magenta

# Trunk : NAT (Internet/pfSense) <-> Switch Port 0
Write-Host "  Cablage: INTERNET-GW <-> SW-CORE (Trunk Port 0)"
New-GNS3Link -NodeId1 $nat.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 0

# VLAN 10 - Serveurs
Write-Host "  Cablage: AD-SRV-2019 <-> SW-CORE (VLAN 10 - Port 1)"
New-GNS3Link -NodeId1 $adServer.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 1

Write-Host "  Cablage: SQL-SRV <-> SW-CORE (VLAN 10 - Port 2)"
New-GNS3Link -NodeId1 $sqlServer.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 2

# VLAN 20 - Employees
Write-Host "  Cablage: PC-EMPLOYEE-1 <-> SW-CORE (VLAN 20 - Port 3)"
New-GNS3Link -NodeId1 $pcEmp1.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 3

Write-Host "  Cablage: PC-EMPLOYEE-2 <-> SW-CORE (VLAN 20 - Port 4)"
New-GNS3Link -NodeId1 $pcEmp2.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 4

# VLAN 30 - R&D
Write-Host "  Cablage: PC-RD-LAB1 <-> SW-CORE (VLAN 30 - Port 5)"
New-GNS3Link -NodeId1 $pcRd1.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 5

Write-Host "  Cablage: PC-RD-LAB2 <-> SW-CORE (VLAN 30 - Port 6)"
New-GNS3Link -NodeId1 $pcRd2.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 6

# VLAN 100 - Management
Write-Host "  Cablage: PC-ADMIN-MGMT <-> SW-CORE (VLAN 100 - Port 7)"
New-GNS3Link -NodeId1 $pcMgmt.node_id -Adapter1 0 -Port1 0 -NodeId2 $switch.node_id -Adapter2 0 -Port2 7

# ============================================================
# ETAPE 5 : Démarrer tous les noeuds
# ============================================================
Write-Host ""
Write-Host "[ETAPE 5] Demarrage de tous les noeuds..." -ForegroundColor Magenta

$allNodes = Invoke-RestMethod -Uri "$BASE/nodes" -TimeoutSec 10
foreach ($node in $allNodes) {
    if ($node.node_type -eq "vpcs") {
        Invoke-RestMethod -Uri "$BASE/nodes/$($node.node_id)/start" -Method POST -ContentType "application/json" -TimeoutSec 10 | Out-Null
        Write-Host "  [>] Demarre: $($node.name)" -ForegroundColor Green
    }
}

# ============================================================
# RÉSUMÉ
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " TOPOLOGIE CREEE AVEC SUCCES !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Equipements deployes:" -ForegroundColor White
Write-Host "  - SW-CORE-BIOTECH (Ethernet Switch avec VLANs)" -ForegroundColor White
Write-Host "    Port 0: Trunk (dot1q) -> INTERNET-GW" -ForegroundColor Gray
Write-Host "    Port 1-2: VLAN 10 (SERVERS)" -ForegroundColor Gray
Write-Host "    Port 3-4: VLAN 20 (EMPLOYEES)" -ForegroundColor Gray
Write-Host "    Port 5-6: VLAN 30 (R&D)" -ForegroundColor Gray
Write-Host "    Port 7:   VLAN 100 (MANAGEMENT)" -ForegroundColor Gray
Write-Host "  - AD-SRV-2019, SQL-SRV (VLAN 10)" -ForegroundColor White
Write-Host "  - PC-EMPLOYEE-1, PC-EMPLOYEE-2 (VLAN 20)" -ForegroundColor White
Write-Host "  - PC-RD-LAB1, PC-RD-LAB2 (VLAN 30)" -ForegroundColor White
Write-Host "  - PC-ADMIN-MGMT (VLAN 100)" -ForegroundColor White
Write-Host "  - INTERNET-GW (NAT)" -ForegroundColor White
Write-Host ""
Write-Host " Ouvrez le projet 'SmartOffice-2.0' dans GNS3 pour voir la topologie !" -ForegroundColor Yellow
