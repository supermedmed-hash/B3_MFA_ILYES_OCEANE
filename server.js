const express = require('express');
const { Client } = require('pg');
const mongoose = require('mongoose');

const app = express();
const port = process.env.PORT || 3000;

// --- Configuration des bases de données ---

// 1. Connexion PostgreSQL (Relationnel : Utilisateurs, Salles, Réservations)
const pgClient = new Client({
    user: process.env.POSTGRES_USER || 'admin_postgres',
    host: process.env.POSTGRES_HOST || 'localhost',
    database: process.env.POSTGRES_DB || 'smartoffice',
    password: process.env.POSTGRES_PASSWORD || 'secret_postgres',
    port: 5432,
});

let pgStatus = '🔴 Hors ligne';
pgClient.connect()
    .then(() => {
        console.log('Connecté avec succès à PostgreSQL');
        pgStatus = '🟢 En ligne';
    })
    .catch(err => {
        console.error('Erreur de connexion PostgreSQL :', err.message);
    });

// 2. Connexion MongoDB (NoSQL : Logs d'accès, Capteurs IoT)
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/smartoffice_iot';
let mongoStatus = '🔴 Hors ligne';

mongoose.connect(mongoUri)
    .then(() => {
        console.log('Connecté avec succès à MongoDB');
        mongoStatus = '🟢 En ligne';
    })
    .catch(err => {
        console.error('Erreur de connexion MongoDB :', err.message);
    });

// --- Routes de l'application ---

app.get('/', (req, res) => {
    // Page d'accueil HTML simple pour visualiser l'état de l'infrastructure
    const html = `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Smart Office 2.0 - PoC</title>
        <style>
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                background-color: #f4f7f6; 
                color: #333; 
                text-align: center; 
                padding: 50px; 
            }
            .container { 
                background: white; 
                padding: 40px; 
                border-radius: 12px; 
                box-shadow: 0 10px 15px rgba(0,0,0,0.1); 
                max-width: 650px; 
                margin: auto; 
            }
            h1 { color: #2c3e50; }
            .status-box { 
                margin: 20px 0; 
                padding: 20px; 
                border: 1px solid #eee; 
                border-radius: 8px; 
                font-size: 1.1em; 
                display: flex; 
                justify-content: space-between; 
                align-items: center;
                background-color: #fafbfc;
            }
            .tech-stack { 
                margin-top: 30px; 
                font-size: 0.9em; 
                color: #7f8c8d; 
                border-top: 1px solid #eee;
                padding-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🏢 Smart Office 2.0</h1>
            <p>Proof of Concept - API & Connecteurs Base de données</p>
            
            <div class="status-box">
                <span style="text-align:left;">
                    <strong>[SQL] PostgreSQL</strong><br>
                    <small>Gestion des entités métiers (Utilisateurs, Réservations)</small>
                </span>
                <span style="font-size: 1.3em;">${pgStatus}</span>
            </div>
            
            <div class="status-box">
                <span style="text-align:left;">
                    <strong>[NoSQL] MongoDB</strong><br>
                    <small>Logs massifs & Capteurs IoT</small>
                </span>
                <span style="font-size: 1.3em;">${mongoStatus}</span>
            </div>

            <div class="tech-stack">
                <p>Propulsé par Node.js & Express | Conteneurisé avec Docker</p>
            </div>
        </div>
    </body>
    </html>
    `;
    res.send(html);
});

app.listen(port, () => {
    console.log(`Serveur web Application Démarré sur le port ${port}`);
});
