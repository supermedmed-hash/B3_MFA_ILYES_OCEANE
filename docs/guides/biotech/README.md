# 🏁 Guide d'Installation Rapide - Biotech Corp Hybrid Cloud

Bienvenue dans le dépôt technique de Biotech Corp. Ce guide permet de mettre en place l'infrastructure hybride complète (GNS3 + Azure) en suivant un ordre logique.

## 🛠️ Ordre de déploiement (Le "One-Shot")
Pour réussir l'installation du premier coup, suivez les modules dans cet ordre précis :

1.  **[Module 01 - Switching](01_gns3_switching.md)** : Préparez le cœur de réseau local (VLANs).
2.  **[Module 02 - pfSense](02_pfsense_vlan_firewall.md)** : Configurez le routage et la sécurité locale.
3.  **[Module 03 - Azure Prep](03_azure_cloud_prep.md)** : Lancez la création de la Gateway Azure (elle met 25min à se créer, faites-le tôt !).
4.  **[Module 04 - VPN Tunnel](04_vpn_site_to_site.md)** : Liez votre GNS3 au Cloud une fois la Gateway Azure prête.
5.  **[Module 05 - AD Replication](05_ad_replication.md)** : Finalisez en étendant le domaine Active Directory.

## 📋 Pré-requis pour les collaborateurs
*   **GNS3** avec la GNS3 VM installée.
*   Appliance **pfSense** (Community Edition).
*   Appliance **Cisco IOS** (L2/L3).
*   Un compte **Azure** avec des crédits (ou abonnement étudiant).
