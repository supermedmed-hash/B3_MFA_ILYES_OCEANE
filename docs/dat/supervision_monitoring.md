# 👁️ Architecture de Supervision et Observabilité — Smart Office 2.0
**Auteur :** Florian (Lead Supervision & Observabilité) | **Statut :** Validé
**Contexte :** Monitoring proactif de l'infrastructure hybride et alerting en temps réel.

Afin de garantir une haute disponibilité (SLA 99.9%) et de fournir des métriques lisibles aux équipes métier, l'infrastructure s'appuie sur une stack de supervision double : **Zabbix** pour l'infrastructure profonde et **Grafana** pour la visualisation des données métier IoT.

---

## 1. Topologie de Supervision (Zabbix)

Zabbix est le cœur de la supervision technique. Déployé sur le serveur `SRV-ZABBIX` (VLAN 100), il interroge activement tous les composants du réseau local et Cloud via des agents et du SNMP.

### 1.1 Périmètre surveillé
*   **Réseau (SNMPv3)** : pfSense (Bande passante WAN/LAN, état du tunnel IPsec), Switchs Cisco (Trafic des ports), AP Wi-Fi.
*   **Serveurs locaux (Zabbix Agent)** : SRV-AD-LOCAL (Charge CPU, RAM, services AD), SRV-DOCKER (Statut du démon Docker, charge globale).
*   **Cloud Azure (Agent/API)** : Surveillance de la passerelle VPN Azure et du conteneur App Service.
*   **Bases de données** : Templates Zabbix pour PostgreSQL (connexions actives, deadlocks) et MongoDB (Taille des collections, QPS).

### 1.2 Flux Réseau de Monitoring
Les flux Zabbix nécessitent une ouverture de port spécifique sur le pfSense (règle ACL `ZBX-01` et `ZBX-02` de la matrice des flux) :
*   Du VLAN 100 vers tous les VLANs sur le port `TCP/10050` (Zabbix Agent).
*   Des équipements vers le VLAN 100 sur le port `TCP/10051` (Zabbix Trapper / Active checks).

---

## 2. Tableaux de Bord et Data-Visualisation (Grafana)

Si Zabbix est destiné aux équipes IT (SysAdmin/NetAdmin), **Grafana** (également hébergé sur le VLAN 100) est la vitrine de la donnée pour le management et l'équipe Data.

### 2.1 Sources de Données (Data Sources)
Grafana est connecté à deux bases :
1.  **Le plugin Zabbix** : Pour générer des dashboards graphiques élégants de la santé des serveurs (CPU, RAM, Disque) et du réseau (Top talkers).
2.  **La base MongoDB** : Requêtage direct des collections IoT pour afficher en temps réel l'occupation des salles, les mouvements détectés, et l'historique d'utilisation.

### 2.2 Alerting & Notification
*   **Niveau 1 (Avertissement)** : Espace disque > 80%, latence WAN > 50ms. Notification via un Webhook sur un canal Slack dédié à l'équipe IT.
*   **Niveau 2 (Critique)** : Chute du tunnel VPN IPsec, crash du conteneur Node.js Azure, perte de l'AD. Déclenchement d'une alerte pager pour l'administrateur d'astreinte, conformément au **Processus ITSM**.

---

## 3. Déploiement Conteneurisé et Provisionnement Automatique

Sur le `SRV-ZABBIX`, la stack est entièrement déployée via `docker-compose`. Afin de garantir une **restaurabilité totale et automatique**, nous utilisons le mécanisme de **provisioning natif** de Grafana et un script d'automatisation des sauvegardes/restaurations.

### 3.1 Provisionnement automatique de Grafana
Lors du déploiement, Grafana configure automatiquement ses ressources sans intervention manuelle grâce aux répertoires de configuration montés en volume :
*   **Datasources** (`monitoring/grafana/provisioning/datasources/zabbix_mongo.yaml`) : Configure automatiquement la connexion avec l'API Zabbix (`http://zabbix-web:8080/api_jsonrpc.php`) et la base MongoDB.
*   **Dashboards** (`monitoring/grafana/provisioning/dashboards/dashboards.yaml`) : Indique à Grafana de charger tous les fichiers JSON du dossier `monitoring/grafana/dashboards/`.
*   **Modèle de Dashboard** (`monitoring/grafana/dashboards/smartoffice_dashboard.json`) : Dashboard par défaut préchargé contenant des graphiques pour la charge CPU des serveurs et les données d'occupation IoT.

### 3.2 Sauvegarde et Restauration des bases de données
Le script [`backup_restore_db.ps1`](file:///c:/Users/Administrateur/Desktop/Cours/B3/Fil_Rouge/scripts/backup_restore_db.ps1) permet d'automatiser les opérations de sauvegarde et de restauration sur les conteneurs distants via le CLI Azure :

*   **Sauvegarder l'ensemble des bases** :
    ```powershell
    .\scripts\backup_restore_db.ps1 -Action backup
    ```
    *Effet : Génère les dumps de PostgreSQL, MongoDB, et MariaDB (Zabbix) dans le répertoire `/home/admin_smartoffice/backups/` sur chaque VM.*

*   **Restaurer l'ensemble des bases** :
    ```powershell
    .\scripts\backup_restore_db.ps1 -Action restore
    ```
    *Effet : Restaure les dumps correspondants dans les conteneurs de base de données respectifs et redémarre les services pour appliquer la configuration.*

---

*Document rédigé par Florian (Lead Supervision) — Juin 2026*
