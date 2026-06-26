# 🔄 Guide de Restauration et Migration vers un Nouveau Compte Azure
**Auteur :** Florian (Lead Supervision) & Ilyes (Lead Infrastructure)  
**Statut :** Validé | **Contexte :** Migration rapide de l'environnement complet pour réutilisation des crédits Azure.

Ce guide décrit la procédure pas-à-pas pour recréer l'intégralité de la solution **Smart Office 2.0** sur un autre compte/abonnement Azure, à partir des sources poussées sur le dépôt Git.

---

## 📋 Prérequis et Outils nécessaires
Avant de commencer, assurez-vous d'avoir installé sur votre machine d'administration locale :
1.  **Git** : pour cloner le projet.
2.  **Azure CLI** : pour exécuter les commandes d'administration Azure.
3.  **PowerShell 7** (ou Windows PowerShell) : pour faire tourner les scripts de déploiement.
4.  **Python 3** : pour lancer la reconnexion automatique du pfSense.
5.  **GNS3** en cours d'exécution avec la topologie locale lancée.

---

## 🚀 Étape 1 : Connexion au Nouveau Compte Azure
1.  Ouvrez une console PowerShell et authentifiez-vous sur le **nouveau** compte Azure :
    ```powershell
    az login
    ```
2.  Si le compte possède plusieurs abonnements, listez-les pour trouver le bon :
    ```powershell
    az account list --output table
    ```
3.  Sélectionnez l'abonnement cible sur lequel vous souhaitez déployer l'infrastructure :
    ```powershell
    az account set --subscription "Nom-Ou-ID-De-Votre-Abonnement"
    ```

---

## 📂 Étape 2 : Récupération des sources Git
Clonez le dépôt officiel et placez-vous sur la branche de développement (`develop`) :
```bash
git clone https://github.com/supermedmed-hash/B3_MFA_ILYES_OCEANE.git
cd B3_MFA_ILYES_OCEANE
git checkout develop
```

---

## 🏗️ Étape 3 : Déploiement et Connexion Automatique (One-Shot)
Lancez le script maître. Il gère la création automatique de tous les composants Cloud dans Azure et, dès que la passerelle VPN est prête, il enchaîne **automatiquement** sur la configuration locale de GNS3 et pfSense :

```powershell
# Usage standard (si pfSense est situé dans D:\VM\PfSense.vmx)
.\scripts\deploy_everything_master.ps1

# Si votre collègue a un chemin de stockage de VM différent :
.\scripts\deploy_everything_master.ps1 -PfSenseVmxPath "CHEMIN_VERS_VOTRE_PFSENSE.vmx"
```

> [!NOTE]
> *   **Automatisation de bout en bout** : Le script déploie l'infrastructure Azure, alloue la passerelle VPN, récupère sa nouvelle adresse IP publique, vérifie vos prérequis locaux, répare/câble la topologie GNS3, configure l'IP des VPCS locaux, calcule votre IP publique hôte en direct et injecte la configuration réseau/IPsec complète sur pfSense par SSH.
> *   **Durée d'exécution** : Environ **30 minutes** (le temps que la passerelle VPN Azure se construise en arrière-plan).

Une fois le script terminé avec succès :
*   L'infrastructure Azure est opérationnelle.
*   La maquette GNS3 est entièrement configurée.
*   **Le tunnel VPN IPsec est automatiquement configuré et connecté.**

---

## 🔒 Étape 4 : Validation du Tunnel VPN IPsec
Le tunnel se connecte automatiquement à la fin de l'étape 3. Pour le valider manuellement :
1.  Connectez-vous sur l'interface Web de votre pfSense local (`http://192.168.2.145`).
2.  Allez dans le menu **Status > IPsec**.
3.  Vérifiez que le statut de l'association de sécurité (SA) affiche **Established** avec les subnets `10.10.0.0/16` côté local et `10.100.0.0/16` côté Azure.

---

## 💾 Étape 5 : Restauration des Données Métier & Supervision (Optionnel)
Si vous disposez de sauvegardes des bases de données de l'ancienne infrastructure (fichiers `.sql` et `.archive`), vous pouvez les restaurer facilement :

1.  Transférez vos fichiers de sauvegarde dans le dossier `/home/admin_smartoffice/backups/` de vos VMs correspondantes :
    *   `pg_dump.sql` et `mongo_dump.archive` sur la machine **`SRV-DOCKER`**.
    *   `zabbix_dump.sql` sur la machine **`SRV-ZABBIX`**.
2.  Une fois les fichiers déposés, lancez le script de restauration centralisé depuis votre machine d'administration locale :
    ```powershell
    .\scripts\backup_restore_db.ps1 -Action restore
    ```
3.  *Le script injectera automatiquement les dumps dans PostgreSQL, MongoDB, MariaDB et redémarrera le Zabbix Server.*

---

## 📊 Étape 6 : Validation du fonctionnement
*   **Zabbix** : Accédez à la console web Zabbix sur `http://<IP_PUBLIQUE_SRV_ZABBIX>:8085` (ou `8080` sur Azure) avec les identifiants `Admin` / `zabbix`.
*   **Grafana** : Accédez à Grafana sur `http://localhost:3001` (ou `3000` sur la VM) avec les identifiants `admin` / `admin`. Le dashboard **Smart Office 2.0** sera immédiatement actif et provisionné.
*   **Application Web** : Connectez-vous sur l'adresse de votre App Service pour vérifier que les réservations fonctionnent.

---

## 🛑 Étape 7 : Nettoyage et destruction des coûts
Afin d'éviter de vider les crédits de votre nouveau compte d'un coup, n'oubliez pas de lancer le script de pause ou de détruire les groupes de ressources une fois vos tests validés :

```powershell
# Option A : Pause de la facturation des VMs et de l'App Service
.\scripts\pause_azure.ps1

# Option B : Destruction définitive de toute l'infrastructure (zéro coût restant)
az group delete --name RG-SmartOffice-Prod --yes --no-wait
az group delete --name RG-SmartOffice-IaaS-France --yes --no-wait
```
