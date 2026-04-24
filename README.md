# 🏢 Projet Smart Office 2.0 - B3 Infrastructure

Bienvenue sur le dépôt officiel du projet de fin d'année B3. Ce projet démontre la mise en place d'une architecture hybride sécurisée et d'un pipeline DevOps moderne.

---

## 👥 L'Équipe & Rôles

| Membre | Rôle | Responsabilités |
|--------|------|-----------------|
| **Mehdi** | **Lead DevOps & Data** | **CI/CD, Docker (Multi-container), PostgreSQL, MongoDB, Azure App Service** |
| **Ilyes** | Lead Infrastructure & Sécurité | Configuration réseau, VLANs, Firewall PfSense, VPN IPsec |
| **Océane** | Lead Systèmes & Cloud | Windows Server 2019, Active Directory, Azure AD Sync |
| **Florian** | Lead Supervision | Zabbix, Grafana, Dashboards de performance |

---

## 🚀 Déploiement "One-Shot" sur Azure

Pour déployer ou mettre à jour l'infrastructure complète sur Azure App Service (Multi-container) :

### 1. Pré-requis
- Un **Azure Container Registry (ACR)** pour l'image de l'application.
- Un **App Service Plan** (Linux B1 minimum).

### 2. Variables d'Environnement (App Settings)
Variables configurées pour la résilience :
- `WEBSITES_PORT`: `3000`
- `WEBSITES_CONTAINER_START_TIME_LIMIT`: `1800` (Optimisé pour les bases de données)
- `DOCKER_REGISTRY_SERVER_URL`, `USERNAME`, `PASSWORD` (Secrets ACR)

---

## 🛡️ Optimisations & Résilience (Réalisé)

Dans le cadre du passage au Full Cloud, nous avons implémenté plusieurs optimisations critiques pour garantir la haute disponibilité :

- **Système de Reconnexion Récursif (Retry Logic)** : L'application web intègre désormais une logique de reconnexion automatique. Si PostgreSQL ou MongoDB ne sont pas encore prêts au démarrage, l'application ne crash plus et réessaie toutes les 5 secondes.
- **Gestion via Connection Pooling (`pg.Pool`)** : Passage d'un client unique à un Pool de connexions pour PostgreSQL. Cela permet de gérer plus de requêtes simultanées et d'éviter les blocages "504 Gateway Timeout" sur Azure.
- **Standardisation des Images** : Migration vers des images Docker standards (`mongo:6`) pour garantir la compatibilité avec les registres Cloud et éviter les erreurs de manifeste.

---

## 🛠️ Stack Technique

| Domaine | Technologies |
|---------|-------------|
| **Réseau** | Cisco (GNS3), PfSense, VPN IPsec |
| **Système** | Windows Server 2019, Active Directory, Azure AD |
| **DevOps** | Docker, GitHub Actions, Azure App Service |
| **Data** | PostgreSQL 15, MongoDB 6 |
| **Monitoring** | Zabbix, Grafana |

---

## 📂 Organisation du Dépôt

```
smart-office-2.0/
│
├── .github/workflows/     # 🔄 Workflows CI/CD
├── docs/                  # 📚 Documentation (DAT, Biotech guides)
├── app-reservation/       # 🐳 Application Web (Node.js)
├── infrastructure/        # 🖧 Configs Réseau & Cloud
└── monitoring/            # 📊 Supervision
```

---
*Projet réalisé dans le cadre du cursus B3 Infrastructure - 2025/2026*