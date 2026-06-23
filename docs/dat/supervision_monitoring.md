# 👁️ Architecture de Supervision et Observabilité — Smart Office 2.0
**Auteur :** Mehdi (Lead Supervision & Observabilité) | **Statut :** Validé
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

## 3. Déploiement Conteneurisé

Sur le `SRV-ZABBIX`, la stack est entièrement déployée via `docker-compose` pour faciliter les mises à jour et les sauvegardes :
*   `zabbix-server-mysql` (Moteur de collecte)
*   `zabbix-web-nginx-mysql` (Interface Web d'administration)
*   `mariadb` (Base de données dédiée aux métriques Zabbix)
*   `grafana` (Serveur de visualisation)

*Document rédigé par Mehdi (Lead Supervision) — Juin 2026*
