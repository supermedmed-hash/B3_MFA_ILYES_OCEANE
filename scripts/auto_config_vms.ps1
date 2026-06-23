$ResourceGroup = "RG-SmartOffice-IaaS-France"

Write-Host "🚀 Lancement de la configuration automatique des VMs..." -ForegroundColor Cyan

# 1. SRV-AD-LOCAL (Windows) - DEJA FAIT
Write-Host "✅ SRV-AD-LOCAL est déjà configuré." -ForegroundColor Green

# 2. SRV-DOCKER (Ubuntu)
Write-Host "⏳ Injection du script Docker App dans SRV-DOCKER..." -ForegroundColor Yellow
az vm run-command invoke --command-id RunShellScript --name "SRV-DOCKER" -g $ResourceGroup --scripts "@scripts\setup_docker_app.sh"
Write-Host "✅ Commande envoyée à SRV-DOCKER." -ForegroundColor Green

# 3. SRV-ZABBIX (Ubuntu)
Write-Host "⏳ Injection du script Docker Monitoring dans SRV-ZABBIX..." -ForegroundColor Yellow
az vm run-command invoke --command-id RunShellScript --name "SRV-ZABBIX" -g $ResourceGroup --scripts "@scripts\setup_docker_monitoring.sh"
Write-Host "✅ Commande envoyée à SRV-ZABBIX." -ForegroundColor Green

Write-Host "🎉 Toutes les configurations ont été poussées en arrière-plan avec succès !" -ForegroundColor Green
Write-Host "Les serveurs vont télécharger, installer et redémarrer tout seuls. Comptez environ 5 à 10 minutes pour que tout soit prêt." -ForegroundColor Cyan
