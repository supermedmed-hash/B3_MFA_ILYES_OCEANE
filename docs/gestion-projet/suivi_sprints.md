# 📅 Suivi des Sprints - Smart Office 2.0

Ce document sert de board Kanban interne pour l'équipe B3, synchronisé avec les rôles de chacun.

## 🚀 Sprint en cours : Infrastructure & PoC (Semaine 1)

### 🔴 À Faire (To Do)
*   **[OCÉANE]** Finaliser le VNet Peering entre le réseau AD et le réseau App.
*   **[ILYES]** Configurer les règles de filtrage inter-VLANs sur le PfSense.
*   **[FLORIAN]** Créer les premiers tableaux de bord Grafana pour Postgres.

### 🚧 En Cours (In Progress)
*   **[FLORIAN]** Installation de l'agent Zabbix sur les VMs de test.
*   **[MEHDI]** Rédaction du chapitre 1 du DAT (Contexte & Objectifs).

### ✅ Terminé (Done)
*   **[MEHDI]** Réorganisation du repo : Application déplacée dans `/app-reservation`.
*   **[MEHDI]** Mise en place du pipeline CI/CD GitHub Actions vers Azure ACR.
*   **[MEHDI]** Mise à jour du Dockerfile et du Docker Compose pour la nouvelle structure.
*   **[OCÉANE]** Installation Active Directory local & Azure Replica.
*   **[ILYES]** Plan d'adressage IP validé.
*   **[FLORIAN]** Reprise de l'administration PostgreSQL et Monitoring.

---

## 📊 Backlog Produit (Prochainement)
*   Mise en place de la haute disponibilité (HA) sur le firewall.
*   Tests de pénétration (Pentest) sur l'interface de réservation.
*   Automatisation des backups de la base PostgreSQL vers un Azure Blob Storage.
