# 🏢 Projet Smart Office 2.0 - B3 Infrastructure

Bienvenue sur le dépôt officiel du projet de fin d'année B3.

---

## 👥 L'Équipe

| Membre | Rôle | Responsabilités |
|--------|------|-----------------|
| **Ilyes** | Lead Infrastructure & Sécurité | Configuration réseau, VLANs, Firewall, VPN |
| **Océane** | Lead Systèmes & Cloud Hybride | Windows Server, Active Directory, Azure |
| **Mehdi** | Lead DevOps, Data & Gestion de Projet | CI/CD, Docker, BDD, Supervision, GitHub |

---

## 🎯 Objectifs

Concevoir et déployer une **infrastructure sécurisée et hybride** pour une Biotech en hyper-croissance (50 → 200 employés).

### Livrables Attendus
- ✅ Dossier d'Architecture Technique (DAT)
- ✅ Infrastructure réseau sécurisée (VLANs, Firewall, VPN)
- ✅ Environnement Windows Server + Active Directory
- ✅ Application de réservation conteneurisée (PoC DevOps)
- ✅ Système de supervision centralisée

---

## 🛠️ Stack Technique

| Domaine | Technologies |
|---------|-------------|
| **Réseau** | Cisco (GNS3), PfSense, VPN IPsec |
| **Système** | Windows Server 2019, Active Directory, Azure AD |
| **DevOps** | Docker, GitHub Actions, CI/CD |
| **Data** | PostgreSQL, MongoDB |
| **Monitoring** | Zabbix, Grafana |

---

## 🚀 Comment lancer l'application (PoC)

```bash
# 1. Cloner le dépôt
git clone https://github.com/supermedmed-hash/B3_MFA_ILYES_OCEANE.git

# 2. Aller dans le dossier de l'application
cd app-reservation

# 3. Lancer avec Docker Compose
docker-compose up -d

# 4. Accéder à l'interface
# Ouvrir dans le navigateur : http://localhost:3000
```

---

## 📂 Organisation du Dépôt

```
smart-office-2.0/
│
├── .github/workflows/     # 🔄 Workflows CI/CD (GitHub Actions)
├── docs/                  # 📚 Documentation (DAT, procédures, schémas)
├── app-reservation/       # 🐳 Application Smart Office (Docker)
├── infrastructure/        # 🖧 Configuration réseau & système
├── monitoring/            # 📊 Templates Zabbix & Grafana
└── data/                  # 🗄️ Scripts SQL & NoSQL
```

### Détail des Dossiers

| Dossier | Contenu | Responsable |
|---------|---------|-------------|
| `/docs/dat/` | Dossier d'Architecture Technique | Tous |
| `/docs/procedures/` | Procédures d'installation | Tous |
| `/docs/schemas/` | Schémas réseau (Draw.io, Visio) | Ilyes |
| `/infrastructure/reseau/` | Configs switches/routeurs | Ilyes |
| `/infrastructure/systeme/` | Scripts PowerShell AD | Océane |
| `/infrastructure/cloud/` | Templates Azure (Terraform/JSON) | Océane |
| `/monitoring/zabbix/` | Templates XML Zabbix | Mehdi |
| `/monitoring/grafana/` | Dashboards JSON | Mehdi |
| `/data/sql/` | Scripts PostgreSQL | Mehdi |
| `/data/nosql/` | Scripts MongoDB | Mehdi |

---

## 🌿 Stratégie de Branches

Nous utilisons **GitFlow simplifié** :

| Branche | Usage | Qui peut merger ? |
|---------|-------|-------------------|
| `main` | Version présentable au jury (stable) | Mehdi uniquement |
| `develop` | Branche d'intégration | Équipe |
| `feat/*` | Nouvelles fonctionnalités | Chacun |
| `infra/*` | Configuration infrastructure | Ilyes |
| `script/*` | Scripts système | Océane |
| `docs/*` | Documentation | Tous |

### Convention de Nommage

```
type/nom-de-la-tache
```

**Exemples :**
- `feat/docker-app` (Mehdi)
- `infra/vlan-config` (Ilyes)
- `script/ad-users` (Océane)
- `docs/dat-chapitre1`

---

## 🤝 Workflow de Collaboration

1. **Créer une branche** depuis `develop`
2. **Développer** la fonctionnalité
3. **Pousser** la branche sur GitHub
4. **Créer une Pull Request** vers `develop`
5. **Code Review** par Mehdi
6. **Merge** après validation

> ⚠️ **Règle d'or** : Ne jamais push directement sur `main` !

---

## 📞 Contact

Pour toute question sur le projet, contacter l'équipe via le canal Teams du projet.

---

*Projet réalisé dans le cadre du cursus B3 Infrastructure - 2024/2025*
