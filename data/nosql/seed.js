// ==============================================================================
// Smart Office 2.0 — Script de Seed MongoDB (NoSQL)
// Base de données : smartoffice_iot
// Collection : iotlogs
// Auteur : Mehdi (Lead DevOps & Data)
//
// JURY DEFENSE :
// Ce script insère des données de démonstration dans la collection MongoDB
// utilisée pour stocker les logs IoT en temps réel. MongoDB a été choisi
// pour cette tâche car :
//   1. Les logs IoT sont des documents JSON sans schéma fixe (schemaless)
//   2. Le volume d'écriture est très élevé (milliers de capteurs)
//   3. Pas besoin de transactions ACID pour des logs (eventual consistency OK)
//
// Pour exécuter :
//   mongosh smartoffice_iot seed.js
//   ou : docker exec smartoffice_mongo mongosh smartoffice_iot /data/seed.js
// ==============================================================================

// Schéma du document IotLog (Mongoose Schema dans server.js) :
// {
//   salle_nom:    String,     → Nom de la salle concernée
//   action:       String,     → Type d'événement (Création, Suppression, Alerte)
//   utilisateur:  String,     → Identifiant de l'acteur
//   timestamp:    Date        → Horodatage automatique (default: Date.now)
// }

db = db.getSiblingDB('smartoffice_iot');

// Nettoyage de la collection avant insertion (optionnel pour la démo)
db.iotlogs.drop();

// ==========================================
// 1. LOGS DE RÉSERVATION (Flux métier normal)
// ==========================================
db.iotlogs.insertMany([
    {
        salle_nom: "Salle Da Vinci",
        action: "Création",
        utilisateur: "admin",
        timestamp: new Date("2026-07-01T09:15:00Z")
    },
    {
        salle_nom: "Salle Lovelace",
        action: "Création",
        utilisateur: "employe",
        timestamp: new Date("2026-07-01T10:30:00Z")
    },
    {
        salle_nom: "Salle Turing",
        action: "Création",
        utilisateur: "employe",
        timestamp: new Date("2026-07-01T11:00:00Z")
    },
    {
        salle_nom: "Salle Da Vinci",
        action: "Suppression",
        utilisateur: "admin",
        timestamp: new Date("2026-07-01T14:00:00Z")
    },

    // ==========================================
    // 2. LOGS IoT CAPTEURS (Température, occupation)
    // ==========================================
    // Ces logs simulent les données remontées par les capteurs IoT
    // du bâtiment (VLAN 50) vers la base MongoDB (VLAN 10).
    {
        salle_nom: "Salle Da Vinci",
        action: "Capteur_Temperature",
        utilisateur: "iot-sensor-etage2-001",
        timestamp: new Date("2026-07-01T08:00:00Z"),
        valeur: 22.5,
        unite: "°C"
    },
    {
        salle_nom: "Salle Lovelace",
        action: "Capteur_Occupation",
        utilisateur: "iot-sensor-etage3-002",
        timestamp: new Date("2026-07-01T08:05:00Z"),
        valeur: 8,
        unite: "personnes"
    },
    {
        salle_nom: "Salle Turing",
        action: "Capteur_QualiteAir",
        utilisateur: "iot-sensor-etage1-003",
        timestamp: new Date("2026-07-01T08:10:00Z"),
        valeur: 420,
        unite: "ppm_CO2"
    },

    // ==========================================
    // 3. LOG D'ANOMALIE SIMULÉE (Pour la démo jury)
    // ==========================================
    // Ce log simule une anomalie détectée par un capteur :
    // température anormalement élevée dans la salle R&D (VLAN 30).
    // En production, ce type d'alerte déclencherait un trigger Zabbix.
    {
        salle_nom: "Labo R&D - Étage 4",
        action: "ALERTE_Temperature_Critique",
        utilisateur: "iot-sensor-rd-007",
        timestamp: new Date("2026-07-02T03:42:00Z"),
        valeur: 38.7,
        unite: "°C",
        severity: "CRITICAL",
        description: "Température anormale détectée hors heures ouvrées. Vérification requise."
    }
]);

// Création d'un index sur le timestamp pour optimiser les requêtes
// de tri chronologique (utilisé par Grafana pour les dashboards)
db.iotlogs.createIndex({ timestamp: -1 });

// Vérification
print("✅ Seed MongoDB terminé !");
print("   Documents insérés : " + db.iotlogs.countDocuments());
print("   Index créés : " + JSON.stringify(db.iotlogs.getIndexes().map(i => i.name)));
