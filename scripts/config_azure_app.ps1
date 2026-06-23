# 🏢 SCRIPT DE CONFIGURATION APPLICATIVE - SMART OFFICE 2.0
# Ce script configure les variables d'environnement nécessaires au fonctionnement de l'app sur Azure.

# Vérification du PATH (au cas où az n'est pas reconnu)
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    $azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path $azPath) { $env:Path += ";$azPath" }
}

$RG_NAME = "RG-SmartOffice-Prod"
$APP_NAME = "smartoffice-poc-app"

Write-Host "⚙️ Configuration des variables d'environnement sur Azure..." -ForegroundColor Cyan

# 1. Configurer le port de l'application (Crucial pour que le site s'affiche)
# Azure App Service doit savoir que notre container écoute sur le port 3000
az webapp config appsettings set --resource-group $RG_NAME --name $APP_NAME --settings WEBSITES_PORT=3000

# 2. Configurer les accès aux bases de données
# Note: Ces valeurs devront être mises à jour avec les IPs du tunnel VPN de Ilyes
az webapp config appsettings set --resource-group $RG_NAME --name $APP_NAME --settings `
    POSTGRES_HOST="127.0.0.1" `
    POSTGRES_USER="admin_postgres" `
    POSTGRES_DB="smartoffice" `
    POSTGRES_PASSWORD="secret_postgres" `
    MONGO_URI="mongodb://127.0.0.1:27017/smartoffice_iot"

Write-Host "✅ Configuration terminée ! Ton application va redémarrer sur Azure." -ForegroundColor Green
Write-Host "Lien : https://$APP_NAME.azurewebsites.net" -ForegroundColor Green
