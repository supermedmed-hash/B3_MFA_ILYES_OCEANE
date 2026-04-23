# 🚀 Guide de Déploiement Azure & DevOps - Smart Office 2.0

Ce document centralise toute la stratégie de déploiement cloud et les arguments techniques à présenter lors de la soutenance devant le jury.

---

## 🎯 1. La Vision DevOps (Pour le Jury)

Lors de l'oral, vous devez justifier vos choix. Voici les arguments clés pour la partie DevOps :

*   **Pourquoi Docker ?** : "Pour garantir la portabilité. L'application fonctionne de la même manière sur le PC de développement que sur les serveurs Azure. On évite l'effet 'ça marche sur ma machine'."
*   **Pourquoi le Cloud Hybride ?** : "On garde le contrôle des données sensibles et de l'identité en local (AD local), tout en profitant de la puissance et de la scalabilité d'Azure pour l'interface web accessible aux employés."
*   **Pourquoi CI/CD (GitHub Actions) ?** : "Pour automatiser les tâches répétitives. Chaque modification du code est testée, packagée et déployée sans intervention humaine, réduisant ainsi les erreurs de configuration manuelle."

---

## 🛠️ 2. Workflow de Déploiement (Le Pipeline)

Le déploiement suit un cycle automatique appelé **CI/CD** (Continuous Integration / Continuous Deployment) :

1.  **Commit & Push** : Mehdi pousse le code sur la branche `develop`.
2.  **Build Docker** : GitHub Actions récupère le code et construit une image Docker (ex: `smartoffice:latest`).
3.  **Push au Registre (ACR)** : L'image est stockée de manière sécurisée dans l'**Azure Container Registry**. C'est notre "bibliothèque" d'images privée.
4.  **Déploiement sur App Service** : Azure est notifié qu'une nouvelle image est disponible. Il redémarre le service web en téléchargeant la nouvelle version sans coupure (Zero Downtime Deployment).

---

## 🔗 3. Connectivité Hybride (Communication Azure <-> Local)

C'est le point technique crucial pour le jury : **Comment l'app dans le Cloud communique avec les bases et l'IoT en local ?**

*   **Le Tunnel VPN IPsec** : Configuré par Ilyes sur le **PfSense**, il crée un pont sécurisé.
*   **Les Flux** : 
    *   L'application web (Azure) envoie des requêtes à la base MongoDB locale pour lire les logs IoT.
    *   Le serveur Zabbix (Florian) interroge l'état de santé de l'instance Azure via ce même tunnel.
*   **Sécurité** : Aucune donnée ne transite en clair sur Internet. Tout passe par le tunnel chiffré.

---

## 📋 4. Checklist pour l'Équipe (Actions Requises)

### Pour Océane (System/Cloud) :
*   **Azure Resource Group** : Créer un groupe de ressources dédié `RG-SmartOffice-Prod`.
*   **Service Principal** : Générer les identifiants Azure pour GitHub (commande `az ad sp create-for-rbac`).
*   **VNet Peering** : Vérifier que le réseau Azure AD communique bien avec le réseau de l'App Service.

### Pour Florian (Data/Monitoring) :
*   **PostgreSQL Firewall** : Autoriser l'IP de l'App Service Azure (ou passer par un Service Endpoint) pour que Florian puisse administrer la base.
*   **Zabbix Agent** : Installer l'agent Zabbix sur la VM Docker Azure pour remonter les métriques CPU/RAM.

### Pour Ilyes (Network) :
*   **Règles de Firewall** : Autoriser le port 27017 (Mongo) et 5432 (Postgres) uniquement en provenance du subnet Azure via le VPN.

---

## 🎓 5. Mots-clés à placer devant le jury

*   **IaaS / PaaS** : "Nous utilisons du PaaS (App Service) pour l'agilité et de l'IaaS (VMs) pour l'Infrastructure AD."
*   **Infrastructure as Code (IaC)** : "Notre déploiement est décrit dans des fichiers YAML (GitHub Actions / Docker Compose), ce qui permet de reconstruire toute l'infra en quelques minutes."
*   **Scalabilité** : "Si le nombre d'employés passe de 50 à 200, il suffit de changer un curseur dans Azure pour scaler l'app."
*   **Haute Disponibilité** : "Grâce à la réplication AD entre Océane et Azure, si le site local tombe, l'authentification cloud reste possible."

---

*Document rédigé par Mehdi (Lead DevOps) - Avril 2026*
