# ==============================================================================
# 🗑️ SCRIPT DE NETTOYAGE AZURE - SMART OFFICE 2.0
# ==============================================================================
# Ce script supprime INTÉGRALEMENT l'environnement IaaS de démonstration
# pour éviter toute facturation sur le tenant Ynov.
# ==============================================================================

$ResourceGroup = "RG-SmartOffice-IaaS-France"

Write-Host "⚠️ ATTENTION : Vous êtes sur le point de supprimer tout le groupe de ressources '$ResourceGroup'." -ForegroundColor Yellow
Write-Host "Cela détruira le VNet, les Sous-réseaux, les NSG et les 3 VMs (AD, Docker, Zabbix)." -ForegroundColor Yellow
Write-Host ""
$Confirmation = Read-Host "Êtes-vous sûr de vouloir continuer ? (O/N)"

if ($Confirmation -eq 'O' -or $Confirmation -eq 'o') {
    Write-Host "🗑️ Suppression en cours... (Cette opération peut prendre quelques minutes)" -ForegroundColor Cyan
    az group delete --name $ResourceGroup --yes --no-wait
    Write-Host "✅ Ordre de suppression envoyé ! Le groupe de ressources disparaîtra d'ici peu." -ForegroundColor Green
} else {
    Write-Host "❌ Opération annulée." -ForegroundColor Red
}
