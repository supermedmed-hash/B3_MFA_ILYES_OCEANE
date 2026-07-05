-- ==============================================================================
-- Smart Office 2.0 — Script d'Initialisation PostgreSQL
-- Base de données : smartoffice
-- Auteur : Mehdi (Lead DevOps & Data)
--
-- JURY DEFENSE :
-- Ce script crée les tables nécessaires au fonctionnement de l'application
-- de réservation de salles. Il est exécuté automatiquement au premier
-- démarrage de l'application Node.js (via server.js), mais est fourni ici
-- de manière indépendante pour démontrer la modélisation relationnelle.
-- ==============================================================================

-- ==========================================
-- 1. TABLE : USERS (Gestion des identités)
-- ==========================================
-- Justification : Table relationnelle classique pour stocker les identités
-- des collaborateurs. Le champ 'role' permet le contrôle d'accès (RBAC)
-- au niveau applicatif (admin vs user).

CREATE TABLE IF NOT EXISTS users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,  -- ⚠️ PoC : stocké en clair. En production, utiliser bcrypt/argon2.
    role        VARCHAR(20) NOT NULL    -- Valeurs possibles : 'admin', 'user'
);

-- Contrainte d'intégrité : le username doit être unique (évite les doublons)
-- Le type SERIAL auto-incrémente l'ID (séquence PostgreSQL)

-- ==========================================
-- 2. TABLE : RESERVATIONS (Données métier)
-- ==========================================
-- Justification : Table transactionnelle (ACID) pour garantir l'intégrité
-- des réservations. Chaque réservation est horodatée automatiquement.
-- PostgreSQL a été choisi plutôt que MongoDB car les réservations nécessitent
-- une cohérence transactionnelle forte (pas de double-booking).

CREATE TABLE IF NOT EXISTS reservations (
    id                  SERIAL PRIMARY KEY,
    employe_nom         VARCHAR(100) NOT NULL,
    salle_nom           VARCHAR(50) NOT NULL,
    date_reservation    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 3. DONNÉES DE SEED (Comptes PoC)
-- ==========================================
-- ⚠️ AVERTISSEMENT SÉCURITÉ :
-- Ces comptes utilisent des mots de passe en clair pour faciliter la
-- démonstration lors de la soutenance. En environnement de production,
-- les mots de passe seraient hachés avec bcrypt (coût 12) et stockés
-- sous forme de hash ($2b$12$...).
--
-- Comptes de démonstration :
--   Admin  : admin / admin123     → Peut supprimer des réservations
--   User   : employe / employe123 → Peut uniquement créer des réservations

INSERT INTO users (username, password, role)
VALUES ('admin', 'admin123', 'admin')
ON CONFLICT (username) DO NOTHING;

INSERT INTO users (username, password, role)
VALUES ('employe', 'employe123', 'user')
ON CONFLICT (username) DO NOTHING;

-- ==============================================================================
-- FIN DU SCRIPT
-- Pour exécuter manuellement :
--   psql -U admin_postgres -d smartoffice -f init.sql
-- ==============================================================================
