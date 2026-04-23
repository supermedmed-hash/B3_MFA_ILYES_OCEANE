# 🏢 SCRIPT D'INSTALLATION AUTOMATIQUE - SMART OFFICE 2.0
# Ce script crée toute l'infrastructure Azure nécessaire pour le projet.

# Vérification du PATH (au cas où az n'est pas reconnu)
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    $azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path $azPath) {
        $env:Path += ";$azPath"
        Write-Host "ℹ️ Azure CLI trouvé dans le chemin par défaut et ajouté à la session." -ForegroundColor Yellow
    } else {
        Write-Error "❌ Azure CLI n'est pas installé ou introuvable. Merci de l'installer via le guide."
        exit
    }
}

$RG_NAME = "RG-SmartOffice-Prod"
$LOCATION = "francecentral"
$ACR_NAME = "smartofficepoc" + (Get-Random -Maximum 9999) # Nom unique
$PLAN_NAME = "Plan-SmartOffice"
$APP_NAME = "smartoffice-poc-app"

Write-Host "🚀 Démarrage de la création de l'infrastructure Azure..." -ForegroundColor Cyan

# 1. Enregistrement des providers Azure (évite les erreurs de première installation)
Write-Host "⚙️ Enregistrement des services Azure (Container Registry)..."
az provider register --namespace Microsoft.ContainerRegistry

# 2. Création du Groupe de Ressources
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
$JSON_AUTH = (az ad sp create-for-rbac --name "GitHub-DevOps-SmartOffice" --role contributor --scopes "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME" --sdk-auth)

# 6. Récupération des infos ACR pour les secrets GitHub
Write-Host "🔐 Récupération des identifiants de ton registre Docker (ACR)..." -ForegroundColor Yellow
$ACR_CREDENTIALS = (az acr credential show --name $ACR_NAME --resource-group $RG_NAME --query "{username:username, password:passwords[0].value}" -o json | ConvertFrom-Json)

Write-Host "----------------------------------------------------------"
Write-Host "✅ INFRASTRUCTURE AZURE CRÉÉE AVEC SUCCÈS !" -ForegroundColor Green
Write-Host "----------------------------------------------------------"
Write-Host "AJOUTE CES 4 SECRETS DANS TON GITHUB (Settings > Secrets > Actions) :" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. ACR_LOGIN_SERVER : $ACR_NAME.azurecr.io"
Write-Host "2. ACR_USERNAME     : $($ACR_CREDENTIALS.username)"
Write-Host "3. ACR_PASSWORD     : $($ACR_CREDENTIALS.password)"
Write-Host "4. AZURE_CREDENTIALS : (Copie le gros bloc JSON ci-dessous)"
Write-Host ""
Write-Host $JSON_AUTH
Write-Host "----------------------------------------------------------"
Write-Host "🚀 Lien de ton application : https://$APP_NAME.azurewebsites.net" -ForegroundColor Green
