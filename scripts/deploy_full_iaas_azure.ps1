# ==============================================================================
# 🏗️ SCRIPT DE DÉPLOIEMENT IaaS AZURE COMPLET - SMART OFFICE 2.0
# ==============================================================================
# Ce script déploie l'intégralité de l'infrastructure On-Premise sous forme de
# Cloud Privé Virtuel (IaaS) dans Azure.
# Il est conçu pour être sécurisé et ne pas impacter le tenant Ynov.
# ==============================================================================

$ResourceGroup = "RG-SmartOffice-IaaS-France"
$Location = "francecentral"
$VNetName = "vnet-smartoffice"
$VNetPrefix = "10.10.0.0/16"
$AdminUser = "admin_smartoffice"
$AdminPassword = "Password!2026SmartOffice"

# 1. Verification connexion Azure
Write-Host "Verification de la connexion Azure CLI..." -ForegroundColor Cyan
$azCheck = az account show --query name -o tsv 2>$null
if (-not $azCheck) {
    Write-Warning "Vous n'etes pas connecte a Azure. Lancement de 'az login'..."
    az login | Out-Null
}
Write-Host "Connecte au tenant Azure : $azCheck" -ForegroundColor Green

# 2. Creation du Resource Group Isolant
Write-Host "Creation du Groupe de Ressources $ResourceGroup..." -ForegroundColor Cyan
az group create --name $ResourceGroup --location $Location | Out-Null

# 3. Creation du Reseau (VNet) et des Sous-reseaux (VLANs)
Write-Host "Creation du VNet ($VNetPrefix) et des sous-reseaux (VLANs)..." -ForegroundColor Cyan
az network vnet create --resource-group $ResourceGroup --name $VNetName --address-prefixes $VNetPrefix | Out-Null

# VLAN 10 : Serveurs (10.10.10.0/24)
az network vnet subnet create --resource-group $ResourceGroup --vnet-name $VNetName --name "VLAN10-Serveurs" --address-prefixes "10.10.10.0/24" | Out-Null
# VLAN 20 : Employes (10.10.20.0/24)
az network vnet subnet create --resource-group $ResourceGroup --vnet-name $VNetName --name "VLAN20-Employes" --address-prefixes "10.10.20.0/24" | Out-Null
# VLAN 100 : Management (10.10.100.0/24)
az network vnet subnet create --resource-group $ResourceGroup --vnet-name $VNetName --name "VLAN100-Management" --address-prefixes "10.10.100.0/24" | Out-Null

# 4. Creation des Network Security Groups (Simule ACLs pfSense)
Write-Host "Configuration des regles de Pare-feu (NSG)..." -ForegroundColor Cyan
az network nsg create --resource-group $ResourceGroup --name "nsg-serveurs" | Out-Null
# Autoriser le ping, SSH, RDP et acces Web
az network nsg rule create --resource-group $ResourceGroup --nsg-name "nsg-serveurs" --name "Allow-Web-SSH-RDP" --priority 100 --destination-port-ranges 22 80 443 3389 --protocol Tcp --access Allow | Out-Null

# On associe le NSG au VLAN 10
az network vnet subnet update --resource-group $ResourceGroup --vnet-name $VNetName --name "VLAN10-Serveurs" --network-security-group "nsg-serveurs" | Out-Null

# 5. Deploiement des VMs
Write-Host "Deploiement des Machines Virtuelles..." -ForegroundColor Cyan

# SRV-AD-LOCAL (Windows Server 2019)
Write-Host "   -> Deploiement de SRV-AD-LOCAL (Windows Server 2019)..."
az vm create --resource-group $ResourceGroup --name "SRV-AD-LOCAL" --image "Win2019Datacenter" --size "Standard_D2s_v3" --vnet-name $VNetName --subnet "VLAN10-Serveurs" --private-ip-address "10.10.10.10" --admin-username $AdminUser --admin-password $AdminPassword --nsg '""' --no-wait

# SRV-DOCKER (Ubuntu 22.04 LTS)
Write-Host "   -> Deploiement de SRV-DOCKER (Ubuntu 22.04 - PoC Application)..."
az vm create --resource-group $ResourceGroup --name "SRV-DOCKER" --image "Ubuntu2204" --size "Standard_D2s_v3" --vnet-name $VNetName --subnet "VLAN10-Serveurs" --private-ip-address "10.10.10.20" --admin-username $AdminUser --admin-password $AdminPassword --nsg '""' --no-wait

# SRV-ZABBIX (Ubuntu 22.04 LTS)
Write-Host "   -> Deploiement de SRV-ZABBIX (Monitoring)..."
az vm create --resource-group $ResourceGroup --name "SRV-ZABBIX" --image "Ubuntu2204" --size "Standard_D2as_v4" --vnet-name $VNetName --subnet "VLAN100-Management" --private-ip-address "10.10.100.10" --admin-username $AdminUser --admin-password $AdminPassword --nsg '""' --no-wait

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "ORDRE DE DEPLOIEMENT ENVOYE A AZURE AVEC SUCCES !" -ForegroundColor Green
Write-Host "Les 3 serveurs sont en cours de construction en arriere-plan."
Write-Host "Ils seront disponibles d'ici 3 a 5 minutes."
Write-Host "Rendez-vous sur le portail Azure pour suivre la progression dans le groupe de ressources $ResourceGroup."
Write-Host "Identifiants Windows/SSH : $AdminUser / $AdminPassword"
Write-Host "==============================================================================" -ForegroundColor Green
