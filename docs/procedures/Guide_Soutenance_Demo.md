# 🚀 Scénario de Démonstration pour le Jury (Soutenance)

Ce guide détaille pas à pas comment démontrer que votre infrastructure hybride est fonctionnelle, sécurisée, et respecte les contraintes de votre architecture (DAT).

---

## 💡 Le "Pitch" pour le Jury (À lire avant la démo technique)

> *"Pour démontrer notre architecture hybride, nous avons dû adapter la maquette aux limites matérielles de notre hôte local (impossibilité de faire tourner de lourds conteneurs Docker dans GNS3). Par conséquent :*
> * *Les **serveurs locaux (Bases de données, AD, Zabbix)** sont simulés dans un environnement Azure IaaS (réseau `10.10.x.x`).*
> * *L'**Application Web métier** est hébergée sur Azure PaaS (réseau `10.100.x.x`).*
> * *Notre pare-feu **pfSense local sous GNS3** maintient un tunnel VPN IPsec fonctionnel vers l'environnement Azure pour simuler la connectivité des postes employés."*

---

## 🛠️ Étape 1 : Démontrer l'Application Web (PaaS)
**Objectif :** Montrer l'agilité du Cloud et le fonctionnement de l'application.
1. **Ouvrez le navigateur** sur l'URL publique : `https://smartoffice-poc-app.azurewebsites.net`
2. **Montrez l'interface Azure App Service** (Portail Azure > App Service > Configuration) :
   - Montrez que vous utilisez une approche "Conteneur Unique" connectée au registre privé ACR (`smartofficepoc7368.azurecr.io`).
   - Montrez les **Variables d'environnement** : Faites remarquer que les variables `POSTGRES_HOST` et `MONGO_URI` pointent vers des **IPs privées** (`10.10.10.20`), prouvant que l'application cloud ne communique pas avec la BDD via Internet.

## 🛠️ Étape 2 : Démontrer l'Isolation des Données (IaaS)
**Objectif :** Prouver la sécurité Zero-Trust.
1. **Allez sur le portail Azure** > Machine Virtuelle `SRV-DOCKER` (IaaS).
2. **Montrez le Network Security Group (NSG)** `nsg-serveurs` :
   - Montrez à l'écran la règle `Allow-App-To-DBs`.
   - Expliquez : *"Nous avons configuré le pare-feu Azure pour n'autoriser les ports PostgreSQL (5432) et MongoDB (27017) **qu'en provenance stricte** du sous-réseau de notre application web (`10.100.0.0/16`). Toute autre tentative d'accès est rejetée."*

## 🛠️ Étape 3 : Démontrer le Tunnel VPN IPsec (GNS3 ↔ Cloud)
**Objectif :** Prouver la liaison hybride et le routage inter-sites.
1. **Ouvrez votre maquette GNS3** et lancez la console de `pfSense`.
2. Tapez l'option `8` pour accéder au Shell (ou connectez-vous au dashboard web de pfSense).
3. **Prouvez que le VPN est monté :**
   - Tapez la commande `ipsec statusall` dans le Shell.
   - Montrez au jury la ligne `ESTABLISHED` et les sélecteurs de phase 2 qui lient le réseau local (`10.10.0.0/16`) au réseau Cloud Azure (`10.100.0.0/16`).
   - Expliquez : *"Le tunnel IKEv2 est monté et stable, avec un chiffrement robuste AES-256."*

## 🛠️ Étape 4 : Démontrer le fonctionnement réseau (GNS3)
**Objectif :** Prouver que la segmentation VLAN locale est opérationnelle.
1. Toujours dans **GNS3**, ouvrez la console d'un PC Employé simulé (ex: `PC-EMPLOYEE-1` dans le VLAN 20).
2. Faites un `ping` de sa passerelle : `ping 10.10.20.254` (IP LAN de pfSense).
3. *(Optionnel)* Si les règles de routage le permettent, faites un ping depuis un VPCS vers une adresse du réseau IaaS ou vers le DNS simulé (`10.10.10.10`).

---

### ⚠️ Question piège potentielle du Jury :
**Jury :** *"Si vos bases de données sont finalement dans Azure IaaS au lieu de votre NAS local, pourquoi avoir fait un VPN depuis pfSense ?"*
**Votre réponse :** *"Dans la conception architecturale (DAT), les bases de données sont 100% On-Premise. Pour la **démonstration technique**, à cause des quotas Azure for Students et des limites de RAM du PC hébergeant GNS3, nous avons dû externaliser la simulation On-Premise dans Azure IaaS. Le tunnel VPN pfSense prouve que la tuyauterie hybride réseau-à-réseau est opérationnelle. Dans un environnement de production avec des serveurs physiques, le trafic applicatif passerait exactement par ce même tunnel."*
