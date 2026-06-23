# ==============================================================================
# 🔐 SCRIPT DE CONFIGURATION IDENTITE HYBRIDE - SMART OFFICE 2.0
# ==============================================================================
# Ce script configure la partie AZURE (Entra ID) de l'identité hybride.
# Il crée une App Registration pour l'authentification OAuth2/OpenID Connect
# et prépare le tenant pour recevoir la synchronisation Azure AD Connect.
#
# PRÉREQUIS :
#   - Azure CLI installé et connecté (az login)
#   - Droits suffisants sur le tenant (Application Administrator minimum)
#   - L'AD on-premise doit être fonctionnel (Windows Server 2019)
#
# USAGE : .\setup_hybrid_identity.ps1
# ==============================================================================

# --- Vérification Azure CLI ---
if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    $azPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"
    if (Test-Path $azPath) {
        $env:Path += ";$azPath"
        Write-Host "ℹ️ Azure CLI trouvé et ajouté à la session." -ForegroundColor Yellow
    } else {
        Write-Error "❌ Azure CLI n'est pas installé. Installer via : https://aka.ms/installazurecliwindows"
        exit 1
    }
}

# --- Variables de configuration ---
$APP_NAME          = "SmartOffice-Auth"
$APP_SERVICE_URL   = "https://smartoffice-poc-app.azurewebsites.net"
$LOCALHOST_URL     = "http://localhost:3000"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🔐 Configuration Identité Hybride - Smart Office 2.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# --- Étape 1 : Vérification de la connexion Azure ---
Write-Host "⚙️ Étape 1/5 : Vérification de la connexion Azure..." -ForegroundColor Yellow
$account = az account show --query "{name:name, tenantId:tenantId}" -o json 2>$null | ConvertFrom-Json
if (!$account) {
    Write-Error "❌ Vous n'êtes pas connecté à Azure. Exécutez 'az login' d'abord."
    exit 1
}
Write-Host "   ✅ Connecté au tenant : $($account.name)" -ForegroundColor Green
$TENANT_ID = $account.tenantId

# --- Étape 2 : Création de l'App Registration ---
Write-Host ""
Write-Host "⚙️ Étape 2/5 : Création de l'App Registration '$APP_NAME'..." -ForegroundColor Yellow

# Vérifier si l'app existe déjà
$existingApp = az ad app list --display-name $APP_NAME --query "[0].appId" -o tsv 2>$null
if ($existingApp) {
    Write-Host "   ℹ️ L'App Registration '$APP_NAME' existe déjà (appId: $existingApp). Réutilisation." -ForegroundColor Yellow
    $APP_ID = $existingApp
} else {
    $appJson = az ad app create `
        --display-name $APP_NAME `
        --sign-in-audience "AzureADMyOrg" `
        --web-redirect-uris "$APP_SERVICE_URL/.auth/login/aad/callback" "$LOCALHOST_URL/.auth/login/aad/callback" `
        --query "{appId:appId, objectId:id}" -o json | ConvertFrom-Json
    
    $APP_ID = $appJson.appId
    $OBJECT_ID = $appJson.objectId
    Write-Host "   ✅ App Registration créée (appId: $APP_ID)" -ForegroundColor Green
}

# --- Étape 3 : Ajout des permissions Microsoft Graph ---
Write-Host ""
Write-Host "⚙️ Étape 3/5 : Configuration des permissions API (Microsoft Graph)..." -ForegroundColor Yellow

# Permission User.Read (déléguée) — ID standard Microsoft Graph
$GRAPH_API_ID = "00000003-0000-0000-c000-000000000000"
$USER_READ_SCOPE_ID = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"

az ad app permission add --id $APP_ID `
    --api $GRAPH_API_ID `
    --api-permissions "$USER_READ_SCOPE_ID=Scope" 2>$null

Write-Host "   ✅ Permission User.Read (déléguée) ajoutée" -ForegroundColor Green

# --- Étape 4 : Génération du Client Secret ---
Write-Host ""
Write-Host "⚙️ Étape 4/5 : Génération du Client Secret (validité 1 an)..." -ForegroundColor Yellow

$secretJson = az ad app credential reset `
    --id $APP_ID `
    --display-name "SmartOffice-Secret" `
    --years 1 `
    --query "{password:password, tenantId:tenant}" -o json | ConvertFrom-Json

$CLIENT_SECRET = $secretJson.password
Write-Host "   ✅ Client Secret généré" -ForegroundColor Green

# --- Étape 5 : Création du Service Principal ---
Write-Host ""
Write-Host "⚙️ Étape 5/5 : Création du Service Principal..." -ForegroundColor Yellow

$existingSP = az ad sp show --id $APP_ID --query "id" -o tsv 2>$null
if (!$existingSP) {
    az ad sp create --id $APP_ID -o none 2>$null
    Write-Host "   ✅ Service Principal créé" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ Service Principal existe déjà" -ForegroundColor Yellow
}

# --- Résumé ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ CONFIGURATION IDENTITÉ HYBRIDE TERMINÉE !" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 INFORMATIONS À CONFIGURER DANS L'APPLICATION NODE.JS :" -ForegroundColor Cyan
Write-Host "   (Ajouter dans les variables d'environnement du docker-compose.yml" -ForegroundColor Cyan
Write-Host "    ou dans les App Settings de l'Azure App Service)" -ForegroundColor Cyan
Write-Host ""
Write-Host "   AZURE_TENANT_ID     = $TENANT_ID"
Write-Host "   AZURE_CLIENT_ID     = $APP_ID"
Write-Host "   AZURE_CLIENT_SECRET = $CLIENT_SECRET"
Write-Host "   AZURE_REDIRECT_URI  = $APP_SERVICE_URL/.auth/login/aad/callback"
Write-Host ""
Write-Host "------------------------------------------------------------" -ForegroundColor Yellow
Write-Host "📌 ÉTAPES SUIVANTES (manuelles) :" -ForegroundColor Yellow
Write-Host "   1. Installer Microsoft Entra Connect sur le Windows Server 2019 (on-premise)"
Write-Host "   2. Configurer la synchronisation Password Hash Sync"
Write-Host "   3. Vérifier la synchro dans le portail Azure > Entra ID > Azure AD Connect"
Write-Host "   4. Tester l'authentification OAuth sur l'app SmartOffice"
Write-Host "============================================================"
