# 🏢 SCRIPT DE MISE EN PAUSE - SMART OFFICE 2.0
# Ce script arrête les services pour ne pas consommer de crédits Azure.

# Vérification du PATH (au cas où az n'est pas reconnu)
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    $azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path $azPath) { $env:Path += ";$azPath" }
}

$RG_NAME = "RG-SmartOffice-IaaS-France"

Write-Host "⏸️ Mise en pause de l'infrastructure Azure..." -ForegroundColor Yellow

# 1. Arrêt de la Web App
Write-Host "🌐 Arrêt de la Web App..."
az webapp stop --name smartoffice-poc-app --resource-group $ResourceGroup

# 2. Arrêt et désallocation de TOUTES les VMs du groupe (AD, etc.)
$vms = az vm list --resource-group $RG_NAME --query "[].name" -o tsv
foreach ($vm in $vms) {
    Write-Host "💻 Arrêt de la VM : $vm..."
    az vm deallocate --name $vm --resource-group $RG_NAME --no-wait
}

Write-Host "✅ Infrastructure mise en pause. Le calcul ne sera plus facturé." -ForegroundColor Green
