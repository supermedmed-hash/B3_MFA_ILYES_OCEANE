# 🎨 Rendu Architecture Hybride Détaillé - Style Visio

Cette visualisation est spécifiquement basée sur les composants identifiés dans le dépôt **Smart Office 2.0**. Elle intègre les VLANs locaux, les instances Azure spécifiques et la connectivité hybride décrite dans votre cahier des charges.

## 🖼️ Schéma Haute Fidélité (Spécifique au Projet)

![Architecture Hybride Détaillée](file:///c:/Users/Administrateur/Desktop/Cours/B3/Fil_Rouge/docs/schemas/architecture_hybride_visio_detailed.png)

## 🔍 Éléments clés intégrés :

1.  **Côté On-Premise (Biotech HQ)** :
    *   **VLAN 10** : Management.
    *   **VLAN 20** : Serveurs (Windows Server 2019 AD & Docker Host).
    *   **VLAN 30** : Utilisateurs.
    *   **VLAN 40** : Capteurs IoT (Salles Da Vinci, Lovelace, Turing).
    *   **Firewall** : PfSense gérant le tunnel IPsec.
2.  **Côté Azure Cloud** :
    *   **VNet** segmentée en subnets Identity, App et Data.
    *   **Services** : Azure App Service (Node.js), PostgreSQL Flexible et Cosmos DB.
3.  **Supervision** : Intégration de Zabbix et Grafana sur l'ensemble de l'infra.

---

> [!NOTE]
> Ce schéma respecte la répartition des tâches de l'équipe (Ilyes pour le réseau, Océane pour le système/cloud, Florian pour la data/supervision, et Mehdi pour le DevOps/Gestion).
