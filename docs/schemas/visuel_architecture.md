# 🎨 Rendu Architecture Hybride Finale - Style Visio

Ce schéma est le rendu final, **strictement basé sur l'état actuel de la branche `develop`**. Il illustre l'implémentation réelle des conteneurs sur hôte Docker et la segmentation réseau locale.

## 🖼️ Schéma Haute Fidélité (Version Finale)

![Architecture Hybride Finale](file:///c:/Users/Administrateur/Desktop/Cours/B3/Fil_Rouge/docs/schemas/architecture_hybride_finale.png)

## 📋 Conformité avec le Dépôt :

1.  **DevOps** : Affichage des 3 conteneurs (`web`, `postgres`, `mongo`) tels que définis dans le `docker-compose.yml`.
2.  **Réseau** : Respect des VLANs 10, 20, 30 et 40 identifiés dans les configurations d'Ilyes.
3.  **Système** : Architecture hybride AD (Local + Azure VM) gérée par Océane.
4.  **Data/Supervision** : Intégration des rôles de Florian (Zabbix/PostgreSQL).

---

> [!IMPORTANT]
> Ce schéma a été généré pour être 100% fidèle au code source présent dans ce dépôt. Il peut être utilisé sans modification pour votre rendu de projet B3.
