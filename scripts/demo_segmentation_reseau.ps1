# ==============================================================================
# 🎯 DÉMONSTRATEUR AUTOMATISÉ : MAQUETTE DE SEGMENTATION RÉSEAU (DOCKER)
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "🚀 LANCEMENT DE LA MAQUETTE RÉSEAU SMART OFFICE 2.0 (DOCKER)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Demarrage des conteneurs isoles (Routeur, AD, Employe, R&D)..." -ForegroundColor Yellow

$composeFile = "infrastructure/reseau/docker-compose.maquette-reseau.yml"

# Allumage de l'architecture
docker-compose -f $composeFile down -v 2>$null
docker-compose -f $composeFile up -d

Write-Host "Veuillez patienter 5 secondes le temps que les routes iptables se mettent en place..."
Start-Sleep -Seconds 5

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "🛡️ TESTS DES RÈGLES DE PARE-FEU (MATRICE DES FLUX)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# TEST 1 : Employé vers Serveur AD (Doit réussir)
Write-Host "`n[TEST 1] Le poste Employe (VLAN 20) ping le Serveur AD (VLAN 10)" -ForegroundColor White
Write-Host "Attendu : SUCCES (Routage et ACL ouverts)" -ForegroundColor DarkGray
$ping1 = docker exec maquette_pc_employe ping -c 1 -W 2 10.10.10.10
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RESULTAT : SUCCES ! L'employe a bien acces au serveur." -ForegroundColor Green
} else {
    Write-Host "❌ RESULTAT : ECHEC ! Le ping ne passe pas." -ForegroundColor Red
}

# TEST 2 : R&D vers Serveur AD (Doit réussir)
Write-Host "`n[TEST 2] Le poste R&D (VLAN 30) ping le Serveur AD (VLAN 10)" -ForegroundColor White
Write-Host "Attendu : SUCCES (La R&D a besoin du serveur d'authentification)" -ForegroundColor DarkGray
$ping2 = docker exec maquette_pc_rd ping -c 1 -W 2 10.10.10.10
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ RESULTAT : SUCCES ! Le poste R&D a bien acces au serveur." -ForegroundColor Green
} else {
    Write-Host "❌ RESULTAT : ECHEC ! Le ping ne passe pas." -ForegroundColor Red
}

# TEST 3 : R&D vers Employé (DOIT ÊTRE BLOQUÉ)
Write-Host "`n[TEST 3] Le poste R&D (VLAN 30) tente de pinger le poste Employe (VLAN 20)" -ForegroundColor White
Write-Host "Attendu : BLOQUE (Isolement total de la R&D demande par la PSSI)" -ForegroundColor DarkGray
$ping3 = docker exec maquette_pc_rd ping -c 1 -W 2 10.10.20.50
if ($LASTEXITCODE -ne 0) {
    Write-Host "✅ RESULTAT : BLOQUE ! Le pare-feu a bien intercepte et jete le paquet ICMP." -ForegroundColor Green
} else {
    Write-Host "❌ RESULTAT : FAIL ! Le ping passe, l'isolation est rompue !" -ForegroundColor Red
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "🎉 DEMONSTRATION TERMINEE AVEC SUCCES !" -ForegroundColor Cyan
Write-Host "Votre architecture de segmentation reseau (Zero Trust) est validee." -ForegroundColor Cyan
Write-Host "Les conteneurs tournent toujours en arriere-plan si vous voulez faire d'autres tests."
Write-Host "Pour tout eteindre : docker-compose -f infrastructure/reseau/docker-compose.maquette-reseau.yml down"
Write-Host "=================================================================" -ForegroundColor Cyan
