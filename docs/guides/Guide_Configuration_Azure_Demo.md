# 🚀 Guide de Configuration Pas-à-Pas (Démo Azure)

Ce guide contient **exclusivement** les lignes de commandes à copier-coller pour configurer vos 3 machines virtuelles fraîchement créées sur Azure, afin d'être prêt pour la démonstration de la soutenance.

## 🛠️ Pré-requis : Se connecter aux VMs

- **Identifiant par défaut** : `admin_smartoffice`
- **Mot de passe par défaut** : `Password!2026SmartOffice`
- Vous trouverez les adresses IP Publiques de chaque machine sur le [Portail Azure](https://portal.azure.com), dans le groupe de ressources `RG-SmartOffice-IaaS-France`.

---

## 1️⃣ SRV-AD-LOCAL (Windows Server 2019)

**Objectif :** Promouvoir le serveur en Contrôleur de Domaine (Active Directory) avec le domaine `smartoffice.local`.

1. Connectez-vous en **Bureau à Distance (RDP)** avec l'IP Publique de la machine.
2. Ouvrez un terminal **PowerShell en tant qu'Administrateur**.
3. Copiez-collez les commandes suivantes une par une :

```powershell
# 1. Installer le rôle Active Directory Domain Services (AD DS) et ses outils de gestion
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# 2. Promouvoir le serveur en Contrôleur de Domaine (Création d'une nouvelle forêt)
# /!\ Cette commande va redémarrer le serveur automatiquement à la fin.
Install-ADDSForest -DomainName "smartoffice.local" -InstallDns:$true -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -LogPath "C:\Windows\NTDS" -SysvolPath "C:\Windows\SYSVOL" -NoRebootOnCompletion:$false -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "Password!2026SmartOffice" -AsPlainText -Force)
```

*(Attendez que la machine redémarre. La connexion RDP va se couper, c'est normal. Reconnectez-vous après 2-3 minutes).*

```powershell
# 3. Créer un Utilisateur de test (employé)
New-ADUser -Name "Jean Dupont" -GivenName "Jean" -Surname "Dupont" -SamAccountName "jdupont" -UserPrincipalName "jdupont@smartoffice.local" -Path "CN=Users,DC=smartoffice,DC=local" -AccountPassword (ConvertTo-SecureString "Password!2026SmartOffice" -AsPlainText -Force) -Enabled $true
```

---

## 2️⃣ SRV-DOCKER (Ubuntu 22.04)

**Objectif :** Installer Docker et lancer l'application métier et les bases de données.

1. Connectez-vous en **SSH** depuis votre PC : `ssh admin_smartoffice@<IP_PUBLIQUE_SRV_DOCKER>`
2. Copiez-collez ce bloc de commandes :

```bash
# 1. Mettre à jour le système et installer les prérequis
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git

# 2. Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Ajouter l'utilisateur courant au groupe docker pour éviter de taper 'sudo' à chaque fois
sudo usermod -aG docker $USER
newgrp docker

# 5. Récupérer le code de l'application (Dépôt Git) et lancer les conteneurs
# (Remplacer l'URL par le vrai lien vers votre dépôt Git)
git clone https://github.com/IlyesL/SmartOffice-B3.git smartoffice
cd smartoffice/infrastructure
docker-compose up -d
```

*(L'application sera alors accessible sur l'IP publique de cette machine, port 80 ou le port défini dans le docker-compose).*

---

## 3️⃣ SRV-ZABBIX (Ubuntu 22.04)

**Objectif :** Installer le serveur de Supervision Zabbix pour monitorer l'infrastructure.

1. Connectez-vous en **SSH** depuis votre PC : `ssh admin_smartoffice@<IP_PUBLIQUE_SRV_ZABBIX>`
2. Copiez-collez ces commandes (Installation de Zabbix 6.4 avec PostgreSQL) :

```bash
# 1. Mettre à jour le système
sudo apt update && sudo apt upgrade -y

# 2. Télécharger et installer le dépôt Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo apt update

# 3. Installer le serveur Zabbix, l'interface web et l'agent
sudo apt install -y zabbix-server-pgsql zabbix-frontend-php php8.1-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# 4. Installer et configurer la base de données locale (PostgreSQL)
sudo apt install -y postgresql postgresql-contrib
sudo -u postgres createuser --pwprompt zabbix  # => Tapez 'zabbix' comme mot de passe quand demandé
sudo -u postgres createdb -O zabbix zabbix

# 5. Importer le schéma de base de données de Zabbix
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# 6. Configurer le mot de passe dans le fichier Zabbix Server
sudo sed -i 's/# DBPassword=/DBPassword=zabbix/g' /etc/zabbix/zabbix_server.conf

# 7. Démarrer et activer les services
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
```

3. **Accès Web :** Ouvrez votre navigateur et allez sur `http://<IP_PUBLIQUE_SRV_ZABBIX>/zabbix`.
4. Suivez l'assistant d'installation (Mot de passe BDD : `zabbix`).
5. **Connexion Zabbix :** User: `Admin` (avec un grand A), Password: `zabbix`.

---

## 🎉 Ce que cela prouve au jury :
En exécutant ces quelques commandes, vous démontrez :
- Vos compétences **Système** (Windows Server / Linux)
- Vos compétences **DevOps** (Docker, Git)
- Vos compétences **Supervision** (Zabbix)
- Votre capacité à déployer et infogérer une **Infrastructure IaaS Cloud (Azure)** de A à Z.
