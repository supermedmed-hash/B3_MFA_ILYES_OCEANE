# ==============================================================================
# 🚀 MASTER SCRIPT DE DEPLOIEMENT INTEGRAL - SMART OFFICE 2.0
# ==============================================================================
# Ce script deploie l'INTEGRALITE de l'infrastructure Azure pour le projet :
#   1. Reseau local virtuel (IaaS RG) + 3 VMs (AD, Docker, Zabbix)
#   2. Reseau VPN & Application PaaS (Prod RG + Web App + ACR)
#   3. Passerelle VPN Gateway + Liaison IPsec avec pfSense
#   4. Post-configuration automatique des VMs (Conteneurs Docker, AD DS)
#
# USAGE : Run inside a PowerShell console logged into the target Azure Account.
# ==============================================================================

param(
    [string]$OnPremPublicIP = "",      # IP publique de pfSense (WAN). Trouvee automatiquement si vide.
    [string]$SharedKey = "SmartOfficeVPN2026Secure",
    [string]$Location = "francecentral",
    [switch]$AutoConnectLocal = $true, # Enchainer automatiquement sur la configuration locale GNS3 & pfSense
    [string]$PfSenseVmxPath = "D:\VM\PfSense.vmx" # Chemin d'accès au fichier VMX de pfSense
)

# Enlever les messages d'avertissement de format
$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🚀 DEPLOIEMENT MASTER INFRASTRUCTURE - SMART OFFICE 2.0" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 0. Verification connexion Azure & Arguments
# ============================================================
Write-Host "[0] Verification de la connexion Azure CLI..." -ForegroundColor Magenta
$azCheck = az account show --query name -o tsv 2>$null
if (-not $azCheck) {
    Write-Warning "Non connecte a Azure. Lancement de 'az login'..."
    az login | Out-Null
    $azCheck = az account show --query name -o tsv
}
Write-Host "  Connecte au compte : $azCheck" -ForegroundColor Green

# Recuperer l'IP publique active si vide
if (-not $OnPremPublicIP) {
    Write-Host "  Recherche de votre IP publique actuelle..." -ForegroundColor Yellow
    $OnPremPublicIP = (Invoke-RestMethod -Uri "https://api.ipify.org")
    Write-Host "  IP Publique On-Premise detectee : $OnPremPublicIP" -ForegroundColor Green
}

$RG_IAAS = "RG-SmartOffice-IaaS-France"
$RG_PROD = "RG-SmartOffice-Prod"
$ACR_NAME = "smartofficepoc" + (Get-Random -Minimum 1000 -Maximum 9999)
$APP_NAME = "smartoffice-poc-app"
$PLAN_NAME = "Plan-SmartOffice"

Write-Host ""
Write-Host "  CONFIGURATION PREVUE :" -ForegroundColor Yellow
Write-Host "  ----------------------" -ForegroundColor Yellow
Write-Host "  Resource Group IaaS  : $RG_IAAS"
Write-Host "  Resource Group Prod  : $RG_PROD"
Write-Host "  Azure Registry (ACR) : $ACR_NAME"
Write-Host "  IP Publique pfSense  : $OnPremPublicIP"
Write-Host "  Cle Partagee IPsec   : $SharedKey"
Write-Host ""

# ============================================================
# 1. Creation des Groupes de Ressources
# ============================================================
Write-Host "[1] Creation des Groupes de Ressources..." -ForegroundColor Magenta
az group create --name $RG_IAAS --location $Location --output none
az group create --name $RG_PROD --location $Location --output none
Write-Host "  [OK] RGs crees" -ForegroundColor Green

# ============================================================
# 2. Deploiement Reseau IaaS (Simulation Site Local)
# ============================================================
Write-Host ""
Write-Host "[2] Creation du Reseau IaaS (vnet-smartoffice)..." -ForegroundColor Magenta
az network vnet create `
    --resource-group $RG_IAAS `
    --name "vnet-smartoffice" `
    --address-prefixes "10.10.0.0/16" `
    --output none

# Creation des Subnets / VLANs
az network vnet subnet create --resource-group $RG_IAAS --vnet-name "vnet-smartoffice" --name "VLAN10-Serveurs" --address-prefixes "10.10.10.0/24" --output none
az network vnet subnet create --resource-group $RG_IAAS --vnet-name "vnet-smartoffice" --name "VLAN20-Employes" --address-prefixes "10.10.20.0/24" --output none
az network vnet subnet create --resource-group $RG_IAAS --vnet-name "vnet-smartoffice" --name "VLAN100-Management" --address-prefixes "10.10.100.0/24" --output none

# Creation et association NSG (Firewall)
az network nsg create --resource-group $RG_IAAS --name "nsg-serveurs" --output none
az network nsg rule create --resource-group $RG_IAAS --nsg-name "nsg-serveurs" --name "Allow-Web-SSH-RDP" --priority 100 --destination-port-ranges 22 80 443 3389 --protocol Tcp --access Allow --output none
az network vnet subnet update --resource-group $RG_IAAS --vnet-name "vnet-smartoffice" --name "VLAN10-Serveurs" --network-security-group "nsg-serveurs" --output none
Write-Host "  [OK] Reseau IaaS configure" -ForegroundColor Green

# ============================================================
# 3. Deploiement des 3 VMs IaaS
# ============================================================
Write-Host ""
Write-Host "[3] Lancement de la creation des VMs en parallele..." -ForegroundColor Magenta
$AdminUser = "admin_smartoffice"
$AdminPassword = "Password!2026SmartOffice"

# VM 1 : Active Directory Domain Controller
Write-Host "  💻 Lancement de SRV-AD-LOCAL (Windows Server 2019)..."
az vm create `
    --resource-group $RG_IAAS `
    --name "SRV-AD-LOCAL" `
    --image "Win2019Datacenter" `
    --size "Standard_D2s_v3" `
    --vnet-name "vnet-smartoffice" `
    --subnet "VLAN10-Serveurs" `
    --private-ip-address "10.10.10.10" `
    --admin-username $AdminUser `
    --admin-password $AdminPassword `
    --nsg '""' `
    --no-wait

# VM 2 : Docker Application Host
Write-Host "  💻 Lancement de SRV-DOCKER (Ubuntu 22.04)..."
az vm create `
    --resource-group $RG_IAAS `
    --name "SRV-DOCKER" `
    --image "Ubuntu2204" `
    --size "Standard_D2s_v3" `
    --vnet-name "vnet-smartoffice" `
    --subnet "VLAN10-Serveurs" `
    --private-ip-address "10.10.10.20" `
    --admin-username $AdminUser `
    --admin-password $AdminPassword `
    --nsg '""' `
    --no-wait

# VM 3 : Zabbix & Grafana Monitoring Host
Write-Host "  💻 Lancement de SRV-ZABBIX (Ubuntu 22.04)..."
az vm create `
    --resource-group $RG_IAAS `
    --name "SRV-ZABBIX" `
    --image "Ubuntu2204" `
    --size "Standard_D2as_v4" `
    --vnet-name "vnet-smartoffice" `
    --subnet "VLAN100-Management" `
    --private-ip-address "10.10.100.10" `
    --admin-username $AdminUser `
    --admin-password $AdminPassword `
    --nsg '""' `
    --no-wait

Write-Host "  [OK] VMs initiees" -ForegroundColor Green

# ============================================================
# 4. Deploiement PaaS (Web App + ACR)
# ============================================================
Write-Host ""
Write-Host "[4] Creation de l'infrastructure Web PaaS..." -ForegroundColor Magenta

# Azure Container Registry
Write-Host "  📦 Creation du Container Registry $ACR_NAME..."
az acr create --resource-group $RG_PROD --name $ACR_NAME --sku Basic --admin-enabled true --output none

# App Service Plan
Write-Host "  🖥️ Creation du Plan App Service Linux..."
az appservice plan create --name $PLAN_NAME --resource-group $RG_PROD --is-linux --sku B1 --output none

# Web App for Containers (App POC)
Write-Host "  🌐 Creation de la Web App..."
az webapp create --resource-group $RG_PROD --plan $PLAN_NAME --name $APP_NAME --deployment-container-image-name "$ACR_NAME.azurecr.io/smartoffice-web:latest" --output none
Write-Host "  [OK] PaaS cree" -ForegroundColor Green

# ============================================================
# 5. Deploiement VPN (Réseau + IP Publique + Gateway)
# ============================================================
Write-Host ""
Write-Host "[5] Initialisation du reseau VPN Azure..." -ForegroundColor Magenta
az network vnet create `
    --resource-group $RG_PROD `
    --name "vnet-smartoffice-vpn" `
    --address-prefixes "10.100.0.0/16" `
    --output none

# Subnets
az network vnet subnet create --resource-group $RG_PROD --vnet-name "vnet-smartoffice-vpn" --name "Subnet-Apps" --address-prefixes "10.100.1.0/24" --output none
az network vnet subnet create --resource-group $RG_PROD --vnet-name "vnet-smartoffice-vpn" --name "GatewaySubnet" --address-prefixes "10.100.254.0/24" --output none

# IP Publique Standard avec Zones pour Gateway
Write-Host "  🌐 Allocation d'une IP Publique Standard redundante de zone..."
az network public-ip create `
    --resource-group $RG_PROD `
    --name "pip-vpn-smartoffice" `
    --allocation-method Static `
    --sku Standard `
    --zone 1 2 3 `
    --output none

$AZURE_VPN_IP = az network public-ip show --resource-group $RG_PROD --name "pip-vpn-smartoffice" --query ipAddress -o tsv
Write-Host "  IP Publique Azure VPN allouee : $AZURE_VPN_IP" -ForegroundColor Green

# VPN Gateway
Write-Host "  🏗️ Lancement de la creation du VPN Gateway (VpnGw1AZ)..."
Write-Host "     ATTENTION : Le Gateway prend environ 30 minutes a se construire en arriere-plan." -ForegroundColor Yellow
az network vnet-gateway create `
    --resource-group $RG_PROD `
    --name "vpn-gw-smartoffice" `
    --vnet "vnet-smartoffice-vpn" `
    --gateway-type Vpn `
    --vpn-type RouteBased `
    --sku VpnGw1AZ `
    --public-ip-address "pip-vpn-smartoffice" `
    --no-wait `
    --output none

# Local Network Gateway (pfSense)
Write-Host "  🏗️ Creation de la configuration Local Network Gateway..."
az network local-gateway create `
    --resource-group $RG_PROD `
    --name "lgw-onprem-pfsense" `
    --gateway-ip-address $OnPremPublicIP `
    --local-address-prefixes "10.10.0.0/16" `
    --output none

# ============================================================
# 6. Post-configuration des VMs et Installation Services (En arriere-plan)
# ============================================================
Write-Host ""
Write-Host "[6] Configuration automatique du contenu des VMs..." -ForegroundColor Magenta

# Attendre 2 minutes que le deploiement initial des VMs soit pret avant d'envoyer les scripts
Write-Host "  ⏳ Attente de 120s pour la stabilisation des VMs..." -ForegroundColor Yellow
Start-Sleep -Seconds 120

# 1. Configurer SRV-DOCKER (Ubuntu - Lancement de l'App & DBs)
Write-Host "  💻 Configuration de SRV-DOCKER (Installation Docker + Reservation App)..."
az vm run-command invoke `
    --command-id RunShellScript `
    --name "SRV-DOCKER" `
    --resource-group $RG_IAAS `
    --scripts "@scripts/setup_docker_app.sh" `
    --no-wait

# 2. Configurer SRV-ZABBIX (Ubuntu - Lancement du Monitoring)
Write-Host "  💻 Configuration de SRV-ZABBIX (Installation Docker + Zabbix Server/Web)..."
az vm run-command invoke `
    --command-id RunShellScript `
    --name "SRV-ZABBIX" `
    --resource-group $RG_IAAS `
    --scripts "@scripts/setup_docker_monitoring.sh" `
    --no-wait

# 3. Configurer SRV-AD-LOCAL (Windows - Installation Active Directory)
Write-Host "  💻 Configuration de SRV-AD-LOCAL (Installation AD-DS et creation Foret)..."
Write-Host "     (La VM va redemarrer automatiquement pour finaliser la promotion AD-DS)" -ForegroundColor Yellow
az vm run-command invoke `
    --command-id RunPowerShellScript `
    --name "SRV-AD-LOCAL" `
    --resource-group $RG_IAAS `
    --scripts "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools; Install-ADDSForest -DomainName 'smartoffice.local' -InstallDns:\$true -CreateDnsDelegation:\$false -DatabasePath 'C:\Windows\NTDS' -LogPath 'C:\Windows\NTDS' -SysvolPath 'C:\Windows\SYSVOL' -NoRebootOnCompletion:\$false -Force:\$true -SafeModeAdministratorPassword (ConvertTo-SecureString 'Password!2026SmartOffice' -AsPlainText -Force)" `
    --no-wait

# ============================================================
# 7. Creation de la connexion VPN IPsec (Une fois le Gateway pret)
# ============================================================
Write-Host ""
Write-Host "[7] En attente de la construction finale du VPN Gateway Azure (VpnGw1AZ)..." -ForegroundColor Magenta
Write-Host "    Le script verifie le statut toutes les 60 secondes en arriere-plan." -ForegroundColor Gray

$attempt = 0
do {
    $attempt++
    $status = az network vnet-gateway show `
        --resource-group $RG_PROD `
        --name "vpn-gw-smartoffice" `
        --query provisioningState -o tsv 2>$null

    if ($status -eq "Succeeded") {
        Write-Host "  [OK] VPN Gateway deploye avec succes !" -ForegroundColor Green
        break
    }
    Write-Host "  [$attempt] Statut VPN Gateway: $status - Prochaine verification dans 60s..." -ForegroundColor Gray
    Start-Sleep -Seconds 60
} while ($attempt -lt 60)

if ($status -ne "Succeeded") {
    Write-Error "Le deploiement du VPN Gateway a pris trop de temps. Le script s'arrete. Vous devrez lancer manuellement les commandes de connexion."
    exit 1
}

# Creer la connexion VPN
Write-Host ""
Write-Host "  🏗️ Liaison du VPN On-Prem et Azure..."
az network vpn-connection create `
    --resource-group $RG_PROD `
    --name "conn-onprem-to-azure" `
    --vnet-gateway1 "vpn-gw-smartoffice" `
    --local-gateway2 "lgw-onprem-pfsense" `
    --shared-key $SharedKey `
    --output none

# Appliquer la politique IPsec standardisee
az network vpn-connection ipsec-policy add `
    --resource-group $RG_PROD `
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

# Post-configuration de l'utilisateur de test AD (apres que la VM ait redemarre de sa promotion)
Write-Host ""
Write-Host "  💻 Creation de l'utilisateur de test AD 'jdupont' sur SRV-AD-LOCAL..."
az vm run-command invoke `
    --command-id RunPowerShellScript `
    --name "SRV-AD-LOCAL" `
    --resource-group $RG_IAAS `
    --scripts "New-ADUser -Name 'Jean Dupont' -GivenName 'Jean' -Surname 'Dupont' -SamAccountName 'jdupont' -UserPrincipalName 'jdupont@smartoffice.local' -Path 'CN=Users,DC=smartoffice,DC=local' -AccountPassword (ConvertTo-SecureString 'Password!2026SmartOffice' -AsPlainText -Force) -Enabled \$true" `
    --output none

# ============================================================
# FIN ET PARAMETRES DE RESTAURATION
# ============================================================
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 🎉 INFRASTRUCTURE DEPLOYEE ET CONFIGUREE AVEC SUCCES !" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Remote Gateway IP (Azure VPN) : $AZURE_VPN_IP" -ForegroundColor White
Write-Host " Pre-Shared Key (PSK)          : $SharedKey" -ForegroundColor White
Write-Host " Web App URL                   : https://$APP_NAME.azurewebsites.net" -ForegroundColor White
Write-Host ""
if ($AutoConnectLocal) {
    Write-Host "🔗 Enchainement automatique : Configuration de l'environnement local GNS3 & pfSense..." -ForegroundColor Magenta
    if (Test-Path "scripts/setup_gns3_pfsense_master.ps1") {
        & "scripts/setup_gns3_pfsense_master.ps1" -AzureVpnIP $AZURE_VPN_IP -PfSenseVmxPath $PfSenseVmxPath
    } else {
        Write-Warning "Le script scripts/setup_gns3_pfsense_master.ps1 est introuvable."
    }
} else {
    Write-Host " 📌 ÉTAPES DE RE-CONNEXION PFSENSE MANUELLE :" -ForegroundColor Yellow
    Write-Host "   1. Ouvre le script 'scripts/pfsense_ssh_config.py'."
    Write-Host "   2. Mets a jour 'remote-gateway' et 'peerid_data' avec : $AZURE_VPN_IP"
    Write-Host "   3. Lance le script python pour reconnecter le tunnel pfSense-Azure."
}
Write-Host ""
Write-Host " Pour supprimer toute l'infra et stopper les couts :" -ForegroundColor Red
Write-Host "   az group delete --name $RG_PROD --yes --no-wait"
Write-Host "   az group delete --name $RG_IAAS --yes --no-wait"
Write-Host ""
