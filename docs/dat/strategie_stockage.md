# 🗄️ Stratégie de Stockage et de Sauvegarde
**Auteur :** Océane & Florian | **Statut :** Validé

La protection du capital de données de Biotech Corp (Comptes utilisateurs, logs IoT, historiques de réservations) nécessite une stratégie de stockage résiliente et un plan de sauvegarde automatisé.

---

## 1. Stratégie de Stockage

### 1.1 Emplacement et Technologies

L'infrastructure repose sur deux environnements de stockage distincts :

| Type de Données | Localisation (On-Premise) | Technologie sous-jacente |
|:---|:---|:---|
| **OS et Hyperviseur (GNS3 VM)** | Serveur physique local (Host) | Disques SSD NVMe (Hautes performances, boot rapide) |
| **Bases de données (PostgreSQL, Mongo)** | VM Docker (Volumes Persistants) | Stockage Bloc (Block Storage) local |
| **Fichiers de sauvegarde & Configs pfSense** | NAS Synology (VLAN 10) | **NAS (Network Attached Storage)** — Disques HDD en RAID 1 (Miroir) |
| **Images Docker (Application Web)** | Azure Container Registry (Cloud) | **Stockage Objet (Object Storage)** managé par Azure |

### 1.2 Justification du choix NAS Local + Cloud
*   **NAS Synology Local** : Offre une grande capacité de stockage à faible coût (HDD) pour les sauvegardes de premier niveau. Permet une restauration très rapide (RTO bas) en réseau local (10 Gbps). Le RAID 1 protège contre la panne d'un disque physique.
*   **Externalisation Cloud** : Protège contre les sinistres majeurs sur le site local (Incendie, vol, ransomware qui chiffrerait le NAS).

---

## 2. Plan de Sauvegarde (Backup)

### 2.1 Règle du "3-2-1" Appliquée
*   **3 copies** des données (1 en production, 1 sur le NAS, 1 dans Azure Blob).
*   **2 supports différents** (Stockage Bloc SSD local et NAS HDD).
*   **1 sauvegarde hors-site** (Cloud Azure Storage, "Air-Gapped").

### 2.2 Planification (Chron)

| Ressource | Type de Sauvegarde | Fréquence | Rétention (Durée de vie) | Outil Utilisé |
|:---|:---|:---|:---|:---|
| **PostgreSQL** (Réservations, Users) | Complète (Dump SQL) | Quotidienne (01:00 AM) | 30 jours | `pg_dump` |
| **MongoDB** (Logs IoT) | Complète (Dump BSON) | Quotidienne (02:00 AM) | 7 jours (Logs non critiques) | `mongodump` |
| **pfSense** | Configuration (XML) | Hebdomadaire (Dimanche) | 3 mois | Script Auto-Backup pfSense |
| **Active Directory** | System State (VSS) | Hebdomadaire | 4 semaines | Windows Server Backup |

---

## 3. Procédure Technique d'Automatisation

Un script PowerShell (détaillé dans `scripts/backup_databases.ps1`) est exécuté chaque nuit par le Planificateur de Tâches Windows ou un Cronjob Linux sur la VM Docker.

**Processus du script :**
1.  Connexion aux conteneurs Docker (`docker exec`).
2.  Génération des fichiers `.sql` (Postgres) et de l'archive tar.gz (Mongo).
3.  Compression ZIP des fichiers avec un horodatage (`YYYY-MM-DD`).
4.  Copie des archives sur le lecteur réseau NAS (partage SMB/NFS `\\NAS-BACKUP\Backups`).
5.  *Optionnel/Évolution : Synchronisation du dossier NAS vers Azure Blob Storage.*
