<#
.SYNOPSIS
    Script d'automatisation des sauvegardes des bases de données PostgreSQL et MongoDB exécutées via Docker.

.DESCRIPTION
    Ce script se connecte au serveur Docker local, exécute les commandes de dump (pg_dump et mongodump),
    compresse les fichiers résultants et les déplace vers un lecteur réseau NAS.
    Prévu pour être exécuté via le Planificateur de tâches Windows (Task Scheduler).

.AUTHOR
    Florian & Océane
#>

$BackupDir = "C:\Backups_Temp"
$NasPath = "\\10.10.10.30\Backups"
$DateStr = Get-Date -Format "yyyy-MM-dd_HH-mm"
$RetentionDays = 30

# Variables Docker / Conteneurs
$PgContainer = "smartoffice_postgres"
$MongoContainer = "smartoffice_mongo"
$PgUser = "admin_postgres"
$PgDb = "smartoffice"

# Création du dossier temp s'il n'existe pas
If (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 🚀 Début de la procédure de sauvegarde BDD..." -ForegroundColor Cyan

# ---------------------------------------------------------
# 1. Sauvegarde PostgreSQL
# ---------------------------------------------------------
$PgBackupFile = "$BackupDir\pg_dump_$DateStr.sql"
Write-Host "-> Sauvegarde de PostgreSQL ($PgDb)..."
# Exécution du dump à l'intérieur du conteneur et redirection vers l'hôte
docker exec -t $PgContainer pg_dump -U $PgUser -d $PgDb > $PgBackupFile

If ($?) {
    Write-Host "✅ Sauvegarde PostgreSQL terminée." -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors de la sauvegarde PostgreSQL." -ForegroundColor Red
}

# ---------------------------------------------------------
# 2. Sauvegarde MongoDB
# ---------------------------------------------------------
$MongoBackupArchive = "$BackupDir\mongo_dump_$DateStr.archive"
Write-Host "-> Sauvegarde de MongoDB (Logs IoT)..."
# Exécution de mongodump (création d'une archive compressée unique)
docker exec -t $MongoContainer mongodump --archive --gzip > $MongoBackupArchive

If ($?) {
    Write-Host "✅ Sauvegarde MongoDB terminée." -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors de la sauvegarde MongoDB." -ForegroundColor Red
}

# ---------------------------------------------------------
# 3. Transfert vers le NAS Local
# ---------------------------------------------------------
Write-Host "-> Copie des fichiers vers le NAS ($NasPath)..."
Try {
    # Vérifie si le NAS est joignable (ping)
    If (Test-Connection -ComputerName 10.10.10.30 -Count 1 -Quiet) {
        Copy-Item -Path $BackupDir\*.sql -Destination $NasPath -Force
        Copy-Item -Path $BackupDir\*.archive -Destination $NasPath -Force
        Write-Host "✅ Transfert réussi vers le NAS." -ForegroundColor Green
        
        # Nettoyage des fichiers locaux temporaires
        Remove-Item -Path $BackupDir\* -Force
    } else {
        Write-Host "⚠️ NAS injoignable, les sauvegardes sont conservées localement dans $BackupDir." -ForegroundColor Yellow
    }
} Catch {
    Write-Host "❌ Erreur lors du transfert NAS: $_" -ForegroundColor Red
}

# ---------------------------------------------------------
# 4. Rotation des Sauvegardes (Nettoyage NAS)
# ---------------------------------------------------------
Write-Host "-> Nettoyage des sauvegardes datant de plus de $RetentionDays jours..."
Try {
    Get-ChildItem -Path $NasPath\*.* -File | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$RetentionDays) } | Remove-Item -Force
    Write-Host "✅ Nettoyage terminé." -ForegroundColor Green
} Catch {
    Write-Host "⚠️ Impossible de nettoyer le NAS (Peut-être injoignable)." -ForegroundColor Yellow
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 🎉 Procédure terminée." -ForegroundColor Cyan
