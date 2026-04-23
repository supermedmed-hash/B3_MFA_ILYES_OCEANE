# 🏢 SCRIPT DE REPRISE - SMART OFFICE 2.0
# Ce script redémarre les services Azure.

# Vérification du PATH (au cas où az n'est pas reconnu)
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    $azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path $azPath) { $env:Path += ";$azPath" }
}

$RG_NAME = "RG-SmartOffice-Prod"

Write-Host "🚀 Redémarrage de l'infrastructure Azure..." -ForegroundColor Cyan

# 1. Redémarrage de la Web App
Write-Host "🌐 Démarrage de la Web App..."
az webapp start --name smartoffice-poc-app --resource-group $RG_NAME

# 2. Redémarrage de TOUTES les VMs du groupe
$vms = az vm list --resource-group $RG_NAME --query "[].name" -o tsv
foreach ($vm in $vms) {
    Write-Host "💻 Démarrage de la VM : $vm..."
    az vm start --name $vm --resource-group $RG_NAME --no-wait
}

Write-Host "✅ Infrastructure opérationnelle !" -ForegroundColor Green
Write-Host "Lien : https://smartoffice-poc-app.azurewebsites.net" -ForegroundColor Green
