# 🏢 SCRIPT D'INSTALLATION AUTOMATIQUE - SMART OFFICE 2.0
# Ce script crée toute l'infrastructure Azure nécessaire pour le projet.

$RG_NAME = "RG-SmartOffice-Prod"
$LOCATION = "francecentral"
$ACR_NAME = "smartofficepoc" + (Get-Random -Maximum 9999) # Nom unique
$PLAN_NAME = "Plan-SmartOffice"
$APP_NAME = "smartoffice-poc-app"

Write-Host "🚀 Démarrage de la création de l'infrastructure Azure..." -ForegroundColor Cyan

# 1. Création du Groupe de Ressources
Write-Host "📂 Création du groupe de ressources..."
az group create --name $RG_NAME --location $LOCATION

# 2. Création de l'Azure Container Registry
Write-Host "📦 Création du registre Docker (ACR)..."
az acr create --resource-group $RG_NAME --name $ACR_NAME --sku Basic --admin-enabled true

# 3. Création du Plan App Service (Linux)
Write-Host "🖥️ Création du plan App Service..."
az appservice plan create --name $PLAN_NAME --resource-group $RG_NAME --is-linux --sku B1

# 4. Création de la Web App
Write-Host "🌐 Création de la Web App..."
az webapp create --resource-group $RG_NAME --plan $PLAN_NAME --name $APP_NAME --deployment-container-image-name "$ACR_NAME.azurecr.io/smartoffice-web:latest"

# 5. Création du Service Principal pour GitHub
Write-Host "🔑 Génération de la clé pour GitHub Actions (AZURE_CREDENTIALS)..."
$SUB_ID = (az account show --query id -o tsv)
az ad sp create-for-rbac --name "GitHub-DevOps-SmartOffice" --role contributor --scopes "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME" --sdk-auth

Write-Host "✅ Terminé ! Copie le JSON ci-dessus dans tes secrets GitHub (AZURE_CREDENTIALS)." -ForegroundColor Green
Write-Host "Lien de ton application : https://$APP_NAME.azurewebsites.net" -ForegroundColor Green
