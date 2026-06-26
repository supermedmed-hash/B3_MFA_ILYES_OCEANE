# ==============================================================================
# 💾 SCRIPT DE SAUVEGARDE & RESTAURATION HYBRIDE - SMART OFFICE 2.0
# ==============================================================================
# Ce script permet de sauvegarder ou de restaurer l'ensemble des bases de données
# du projet à distance sur vos VMs Azure (PostgreSQL, MongoDB, Zabbix/MariaDB).
#
# USAGE :
#   .\scripts\backup_restore_db.ps1 -Action backup
#   .\scripts\backup_restore_db.ps1 -Action restore
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("backup", "restore")]
    [string]$Action,

    [string]$ResourceGroup = "RG-SmartOffice-IaaS-France",
    [string]$DockerVM = "SRV-DOCKER",
    [string]$ZabbixVM = "SRV-ZABBIX"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 💾 GESTION DES BASES DE DONNÉES - SMART OFFICE 2.0" -ForegroundColor Cyan
Write-Host " Action choisie : $Action" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier la connexion Azure CLI
Write-Host "[1] Vérification de la connexion Azure CLI..." -ForegroundColor Magenta
$azCheck = az account show --query name -o tsv 2>$null
if (-not $azCheck) {
    Write-Error "Vous n'êtes pas connecté à Azure. Lisez le guide d'utilisation ou exécutez 'az login'."
}
Write-Host "  Connecté au compte : $azCheck" -ForegroundColor Green

if ($Action -eq "backup") {
    # ==========================================
    # PROCÉDURE DE SAUVEGARDE (BACKUP)
    # ==========================================
    Write-Host ""
    Write-Host "[2] Exécution des sauvegardes à distance..." -ForegroundColor Magenta

    # A. Sauvegarde PostgreSQL & MongoDB sur SRV-DOCKER
    Write-Host "  💻 Connexion à $DockerVM..." -ForegroundColor Yellow
    $dockerCmds = @(
        "mkdir -p /home/admin_smartoffice/backups",
        "echo '-> Sauvegarde de PostgreSQL...'",
        "docker exec -t smartoffice_postgres pg_dump -U admin_postgres -d smartoffice > /home/admin_smartoffice/backups/pg_dump.sql",
        "echo '-> Sauvegarde de MongoDB (IoT logs)...'",
        "docker exec -t smartoffice_mongo mongodump --archive --gzip > /home/admin_smartoffice/backups/mongo_dump.archive",
        "echo '✅ Sauvegardes terminées sur $DockerVM'",
        "ls -la /home/admin_smartoffice/backups"
    ) -join " && "

    Write-Host "    Lancement du dump (Postgres + MongoDB)..."
    $resDocker = az vm run-command invoke `
        --command-id RunShellScript `
        --name $DockerVM `
        --resource-group $ResourceGroup `
        --scripts $dockerCmds `
        --query "value[0].message" -o tsv

    Write-Host "    Retour $DockerVM :" -ForegroundColor Gray
    Write-Host $resDocker -ForegroundColor Gray

    # B. Sauvegarde Zabbix (MariaDB) sur SRV-ZABBIX
    Write-Host "  💻 Connexion à $ZabbixVM..." -ForegroundColor Yellow
    $zabbixCmds = @(
        "mkdir -p /home/admin_smartoffice/backups",
        "echo '-> Sauvegarde de MariaDB (Zabbix DB)...'",
        "docker exec -t smartoffice_zabbix_db mariadb-dump -u zabbix -pzabbix_pass zabbix > /home/admin_smartoffice/backups/zabbix_dump.sql",
        "echo '✅ Sauvegarde Zabbix terminée sur $ZabbixVM'",
        "ls -la /home/admin_smartoffice/backups"
    ) -join " && "

    Write-Host "    Lancement du dump (Zabbix)..."
    $resZabbix = az vm run-command invoke `
        --command-id RunShellScript `
        --name $ZabbixVM `
        --resource-group $ResourceGroup `
        --scripts $zabbixCmds `
        --query "value[0].message" -o tsv

    Write-Host "    Retour $ZabbixVM :" -ForegroundColor Gray
    Write-Host $resZabbix -ForegroundColor Gray

    Write-Host ""
    Write-Host "🎉 Sauvegardes terminées avec succès !" -ForegroundColor Green
    Write-Host "Les fichiers de sauvegarde sont situés dans '/home/admin_smartoffice/backups/' sur chaque VM." -ForegroundColor White

} elseif ($Action -eq "restore") {
    # ==========================================
    # PROCÉDURE DE RESTAURATION (RESTORE)
    # ==========================================
    Write-Host ""
    Write-Host "[2] Exécution des restaurations à distance..." -ForegroundColor Magenta

    # A. Restauration PostgreSQL & MongoDB sur SRV-DOCKER
    Write-Host "  💻 Connexion à $DockerVM..." -ForegroundColor Yellow
    $dockerRestoreCmds = @(
        "if [ ! -f /home/admin_smartoffice/backups/pg_dump.sql ]; then echo '❌ Erreur: pg_dump.sql manquant'; exit 1; fi",
        "if [ ! -f /home/admin_smartoffice/backups/mongo_dump.archive ]; then echo '❌ Erreur: mongo_dump.archive manquant'; exit 1; fi",
        "echo '-> Restauration de PostgreSQL...'",
        "docker exec -i smartoffice_postgres psql -U admin_postgres -d smartoffice < /home/admin_smartoffice/backups/pg_dump.sql",
        "echo '-> Restauration de MongoDB...'",
        "docker exec -i smartoffice_mongo mongorestore --archive --gzip --drop < /home/admin_smartoffice/backups/mongo_dump.archive",
        "echo '✅ Restauration applicative effectuée sur $DockerVM !'"
    ) -join " && "

    Write-Host "    Lancement de la restauration (Postgres + MongoDB)..."
    $resDockerRestore = az vm run-command invoke `
        --command-id RunShellScript `
        --name $DockerVM `
        --resource-group $ResourceGroup `
        --scripts $dockerRestoreCmds `
        --query "value[0].message" -o tsv

    Write-Host "    Retour $DockerVM :" -ForegroundColor Gray
    Write-Host $resDockerRestore -ForegroundColor Gray

    # B. Restauration Zabbix (MariaDB) sur SRV-ZABBIX
    Write-Host "  💻 Connexion à $ZabbixVM..." -ForegroundColor Yellow
    $zabbixRestoreCmds = @(
        "if [ ! -f /home/admin_smartoffice/backups/zabbix_dump.sql ]; then echo '❌ Erreur: zabbix_dump.sql manquant'; exit 1; fi",
        "echo '-> Restauration de MariaDB (Zabbix)...'",
        "docker exec -i smartoffice_zabbix_db mariadb -u zabbix -pzabbix_pass zabbix < /home/admin_smartoffice/backups/zabbix_dump.sql",
        "echo '-> Redémarrage du serveur Zabbix pour appliquer les changements...'",
        "docker restart smartoffice_zabbix_server",
        "echo '✅ Restauration supervision effectuée sur $ZabbixVM !'"
    ) -join " && "

    Write-Host "    Lancement de la restauration (Zabbix)..."
    $resZabbixRestore = az vm run-command invoke `
        --command-id RunShellScript `
        --name $ZabbixVM `
        --resource-group $ResourceGroup `
        --scripts $zabbixRestoreCmds `
        --query "value[0].message" -o tsv

    Write-Host "    Retour $ZabbixVM :" -ForegroundColor Gray
    Write-Host $resZabbixRestore -ForegroundColor Gray

    Write-Host ""
    Write-Host "🎉 Restaurations terminées avec succès !" -ForegroundColor Green
    Write-Host "Toutes les bases de données et la configuration Zabbix ont été restaurées." -ForegroundColor White
}
