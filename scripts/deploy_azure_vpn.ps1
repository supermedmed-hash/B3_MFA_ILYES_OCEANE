# ==============================================================================
# 🔒 SCRIPT DE DEPLOIEMENT VPN GATEWAY AZURE - SMART OFFICE 2.0
# ==============================================================================
# Ce script deploie un tunnel VPN Site-to-Site (IPsec IKEv2) entre
# le site On-Premise (pfSense/GNS3) et le Cloud Azure.
#
# ATTENTION : Le VPN Gateway Azure coute environ 0,15 EUR/heure (~110 EUR/mois)
# Pensez a executer destroy_azure_vpn.ps1 apres la demonstration !
# ==============================================================================

param(
    [string]$ResourceGroup = "RG-SmartOffice-Prod",
    [string]$Location = "francecentral",
    [string]$VNetName = "vnet-smartoffice-vpn",
    [string]$OnPremPublicIP = "",  # IP publique de pfSense (a renseigner)
    [string]$SharedKey = ""        # Cle partagee (generee automatiquement si vide)
)

# ============================================================
# 0. Verification connexion Azure
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VPN Gateway Azure - Smart Office 2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[0] Verification Azure CLI..." -ForegroundColor Magenta
$azCheck = az account show --query name -o tsv 2>$null
if (-not $azCheck) {
    Write-Warning "Non connecte a Azure. Lancement de 'az login'..."
    az login | Out-Null
    $azCheck = az account show --query name -o tsv
}
Write-Host "  Connecte au tenant: $azCheck" -ForegroundColor Green

# Generer une cle partagee si non fournie
if (-not $SharedKey) {
    $SharedKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    Write-Host "  Cle partagee generee: $SharedKey" -ForegroundColor Yellow
}

# Recuperer l'IP publique de pfSense si non fournie
if (-not $OnPremPublicIP) {
    Write-Host ""
    Write-Host "  [!] IP publique On-Premise non fournie." -ForegroundColor Yellow
    Write-Host "  Pour trouver votre IP publique, executez sur pfSense :" -ForegroundColor Yellow
    Write-Host '  curl -s https://api.ipify.org' -ForegroundColor Gray
    Write-Host ""
    $OnPremPublicIP = Read-Host "  Entrez l'IP publique de pfSense (WAN)"
    if (-not $OnPremPublicIP) {
        Write-Error "IP publique requise. Abandon."
        exit 1
    }
}

# ============================================================
# 1. Creer le Resource Group (si pas deja fait)
# ============================================================
Write-Host ""
Write-Host "[1] Creation du Resource Group..." -ForegroundColor Magenta
az group create --name $ResourceGroup --location $Location --output none 2>$null
Write-Host "  [OK] $ResourceGroup ($Location)" -ForegroundColor Green

# ============================================================
# 2. Creer le VNet Azure (reseau Cloud)
# ============================================================
Write-Host ""
Write-Host "[2] Creation du VNet Azure (10.100.0.0/16)..." -ForegroundColor Magenta

az network vnet create `
    --resource-group $ResourceGroup `
    --name $VNetName `
    --address-prefixes "10.100.0.0/16" `
    --output none

# Sous-reseau pour les applications
az network vnet subnet create `
    --resource-group $ResourceGroup `
    --vnet-name $VNetName `
    --name "Subnet-Apps" `
    --address-prefixes "10.100.1.0/24" `
    --output none

Write-Host "  [OK] VNet $VNetName cree avec Subnet-Apps (10.100.1.0/24)" -ForegroundColor Green

# ============================================================
# 3. Creer le GatewaySubnet (obligatoire pour VPN Gateway)
# ============================================================
Write-Host ""
Write-Host "[3] Creation du GatewaySubnet..." -ForegroundColor Magenta

az network vnet subnet create `
    --resource-group $ResourceGroup `
    --vnet-name $VNetName `
    --name "GatewaySubnet" `
    --address-prefixes "10.100.254.0/24" `
    --output none

Write-Host "  [OK] GatewaySubnet (10.100.254.0/24) cree" -ForegroundColor Green

# ============================================================
# 4. Creer l'IP Publique pour le VPN Gateway
# ============================================================
Write-Host ""
Write-Host "[4] Creation de l'IP publique Azure VPN..." -ForegroundColor Magenta

az network public-ip create `
    --resource-group $ResourceGroup `
    --name "pip-vpn-smartoffice" `
    --allocation-method Static `
    --sku Standard `
    --zone 1 2 3 `
    --output none

$AZURE_VPN_IP = az network public-ip show `
    --resource-group $ResourceGroup `
    --name "pip-vpn-smartoffice" `
    --query ipAddress -o tsv

Write-Host "  [OK] IP Publique Azure VPN: $AZURE_VPN_IP" -ForegroundColor Green

# ============================================================
# 5. Creer le VPN Gateway (ATTENTION : ~30-45 min de deploiement)
# ============================================================
Write-Host ""
Write-Host "[5] Creation du VPN Gateway (SKU VpnGw1)..." -ForegroundColor Magenta
Write-Host "    ATTENTION : Cette etape prend 30 a 45 minutes !" -ForegroundColor Yellow
Write-Host "    Cout : ~0,15 EUR/heure" -ForegroundColor Yellow

az network vnet-gateway create `
    --resource-group $ResourceGroup `
    --name "vpn-gw-smartoffice" `
    --vnet $VNetName `
    --gateway-type Vpn `
    --vpn-type RouteBased `
    --sku VpnGw1AZ `
    --public-ip-address "pip-vpn-smartoffice" `
    --no-wait `
    --output none

Write-Host "  [OK] VPN Gateway en cours de deploiement (30-45 min)..." -ForegroundColor Green
Write-Host "  Vous pouvez continuer la configuration pfSense en attendant." -ForegroundColor Cyan

# ============================================================
# 6. Creer le Local Network Gateway (represente pfSense)
# ============================================================
Write-Host ""
Write-Host "[6] Creation du Local Network Gateway (pfSense)..." -ForegroundColor Magenta

az network local-gateway create `
    --resource-group $ResourceGroup `
    --name "lgw-onprem-pfsense" `
    --gateway-ip-address $OnPremPublicIP `
    --local-address-prefixes "10.10.0.0/16" `
    --output none

Write-Host "  [OK] Local Gateway cree (IP: $OnPremPublicIP, Reseau: 10.10.0.0/16)" -ForegroundColor Green

# ============================================================
# 7. Attendre que le VPN Gateway soit pret
# ============================================================
Write-Host ""
Write-Host "[7] Attente du deploiement du VPN Gateway..." -ForegroundColor Magenta
Write-Host "    (Vous pouvez aussi verifier dans le portail Azure)" -ForegroundColor Gray

$maxWait = 60  # Verifier toutes les 60 secondes
$attempt = 0
do {
    $attempt++
    $status = az network vnet-gateway show `
        --resource-group $ResourceGroup `
        --name "vpn-gw-smartoffice" `
        --query provisioningState -o tsv 2>$null

    if ($status -eq "Succeeded") {
        Write-Host "  [OK] VPN Gateway deploye avec succes !" -ForegroundColor Green
        break
    }
    Write-Host "  [$attempt] Statut: $status - Prochaine verification dans 60s..." -ForegroundColor Gray
    Start-Sleep -Seconds $maxWait
} while ($attempt -lt 50)

# ============================================================
# 8. Creer la connexion IPsec
# ============================================================
Write-Host ""
Write-Host "[8] Creation de la connexion IPsec..." -ForegroundColor Magenta

az network vpn-connection create `
    --resource-group $ResourceGroup `
    --name "conn-onprem-to-azure" `
    --vnet-gateway1 "vpn-gw-smartoffice" `
    --local-gateway2 "lgw-onprem-pfsense" `
    --shared-key $SharedKey `
    --output none

# Configurer les parametres IPsec/IKE personnalises (correspondant a pfSense)
az network vpn-connection ipsec-policy add `
    --resource-group $ResourceGroup `
    --connection-name "conn-onprem-to-azure" `
    --ike-encryption AES256 `
    --ike-integrity SHA256 `
    --dh-group DHGroup14 `
    --ipsec-encryption AES256 `
    --ipsec-integrity SHA256 `
    --pfs-group PFS2048 `
    --sa-lifetime 3600 `
    --sa-max-size 1024 `
    --output none

Write-Host "  [OK] Connexion IPsec creee !" -ForegroundColor Green

# ============================================================
# RÉSUMÉ FINAL
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VPN AZURE DEPLOYE AVEC SUCCES !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " PARAMETRES A CONFIGURER DANS PFSENSE :" -ForegroundColor Yellow
Write-Host " ========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " Remote Gateway (Azure) : $AZURE_VPN_IP" -ForegroundColor White
Write-Host " Pre-Shared Key         : $SharedKey" -ForegroundColor White
Write-Host " IKE Version            : IKEv2" -ForegroundColor Gray
Write-Host " Phase 1 Encryption     : AES-256" -ForegroundColor Gray
Write-Host " Phase 1 Hash           : SHA256" -ForegroundColor Gray
Write-Host " Phase 1 DH Group       : 14 (2048-bit)" -ForegroundColor Gray
Write-Host " Phase 1 Lifetime       : 28800 seconds" -ForegroundColor Gray
Write-Host " Phase 2 Encryption     : AES-256" -ForegroundColor Gray
Write-Host " Phase 2 Hash           : SHA256" -ForegroundColor Gray
Write-Host " Phase 2 PFS Group      : 14 (2048-bit)" -ForegroundColor Gray
Write-Host " Phase 2 Lifetime       : 3600 seconds" -ForegroundColor Gray
Write-Host " Local Network          : 10.10.0.0/16" -ForegroundColor Gray
Write-Host " Remote Network (Azure) : 10.100.0.0/16" -ForegroundColor Gray
Write-Host ""
Write-Host " IMPORTANT : Reportez ces parametres dans pfSense" -ForegroundColor Red
Write-Host " (VPN > IPsec > Tunnels > Add P1 / Add P2)" -ForegroundColor Red
Write-Host ""
Write-Host " Pour verifier le statut : " -ForegroundColor Cyan
Write-Host " az network vpn-connection show --resource-group $ResourceGroup --name conn-onprem-to-azure --query connectionStatus -o tsv" -ForegroundColor Gray
Write-Host ""
Write-Host " Pour SUPPRIMER et arreter les couts : " -ForegroundColor Red
Write-Host " az group delete --name $ResourceGroup --yes --no-wait" -ForegroundColor Gray
