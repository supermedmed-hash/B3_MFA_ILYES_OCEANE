const express = require('express');
const { Pool } = require('pg');
const mongoose = require('mongoose');
const cookieParser = require('cookie-parser');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser()); // Pour lire rapidement les cookies d'authentification

// ==========================================
// 1. CONFIGURATION POSTGRESQL (Relationnel)
// ==========================================
const pool = new Pool({
    user: process.env.POSTGRES_USER || 'admin_postgres',
    host: process.env.POSTGRES_HOST || 'localhost',
    database: process.env.POSTGRES_DB || 'smartoffice',
    password: process.env.POSTGRES_PASSWORD || 'secret_postgres',
    port: 5432,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

let pgStatus = '🔴 Hors ligne';

async function initializePostgres() {
    let client;
    try {
        client = await pool.connect();
        console.log('Connecté avec succès à PostgreSQL');
        pgStatus = '🟢 En ligne';

        // Création de la table 'users'
        await client.query(`
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                password VARCHAR(50) NOT NULL,
                role VARCHAR(20) NOT NULL
            );
        `);

        // Création de comptes par défaut si la table est vide (PoC)
        const checkUsers = await client.query('SELECT COUNT(*) FROM users');
        if (parseInt(checkUsers.rows[0].count) === 0) {
            await client.query("INSERT INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin')");
            await client.query("INSERT INTO users (username, password, role) VALUES ('employe', 'employe123', 'user')");
            console.log('Comptes par défaut créés: admin/admin123 et employe/employe123');
        }

        // Création de la table 'reservations'
        await client.query(`
            CREATE TABLE IF NOT EXISTS reservations (
                id SERIAL PRIMARY KEY,
                employe_nom VARCHAR(100) NOT NULL,
                salle_nom VARCHAR(50) NOT NULL,
                date_reservation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log('Tables PostgreSQL vérifiées/créées.');
    } catch (err) {
        console.error('Erreur lors de l\'initialisation des tables PostgreSQL, nouvelle tentative dans 5s...', err.message);
        setTimeout(initializePostgres, 5000);
    } finally {
        if (client) client.release();
    }
}

initializePostgres();

// ==========================================
// 2. CONFIGURATION MONGODB (NoSQL)
// ==========================================
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/smartoffice_iot';
let mongoStatus = '🔴 Hors ligne';

const connectMongoWithRetry = () => {
    console.log('Tentative de connexion à MongoDB...');
    mongoose.connect(mongoUri)
        .then(() => {
            console.log('Connecté avec succès à MongoDB');
            mongoStatus = '🟢 En ligne';
        })
        .catch(err => {
            console.error('Erreur de connexion MongoDB, nouvelle tentative dans 5s...', err.message);
            setTimeout(connectMongoWithRetry, 5000);
        });
};

connectMongoWithRetry();

const IotLogSchema = new mongoose.Schema({
    salle_nom: String,
    action: String,
    utilisateur: String,
    timestamp: { type: Date, default: Date.now }
});
const IotLog = mongoose.model('IotLog', IotLogSchema);

// ==========================================
// 3. ROUTES D'AUTHENTIFICATION
// ==========================================

// Gérer la connexion
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const result = await pool.query('SELECT * FROM users WHERE username = $1 AND password = $2', [username, password]);
        if (result.rows.length > 0) {
            const user = result.rows[0];
            // Stockage simplifié de session via cookie (Pour PoC uniquement)
            res.cookie('session', JSON.stringify({ id: user.id, username: user.username, role: user.role }));
            res.redirect('/');
        } else {
            res.status(401).send(`
                <script>
                    alert('Identifiants incorrects');
                    window.location.href = '/';
                </script>
            `);
        }
    } catch (err) {
        res.status(500).send("Erreur de connexion.");
    }
});

// Gérer la déconnexion
app.get('/logout', (req, res) => {
    res.clearCookie('session');
    res.redirect('/');
});


// ==========================================
// 4. ROUTES API (Métier)
// ==========================================

// Middleware pour vérifier la session
const checkAuth = (req, res, next) => {
    if (req.cookies.session) {
        req.user = JSON.parse(req.cookies.session);
        next();
    } else {
        res.status(401).send("Non autorisé.");
    }
};

// Réserver une salle (Accessible à tous les connectés)
app.post('/api/reserver', checkAuth, async (req, res) => {
    const { salle_nom } = req.body;
    const employe_nom = req.user.username; // Le nom vient de la session, impossible à falsifier

    try {
        await pool.query(
            'INSERT INTO reservations (employe_nom, salle_nom) VALUES ($1, $2)',
            [employe_nom, salle_nom]
        );

        const log = new IotLog({
            salle_nom: salle_nom,
            action: 'Création',
            utilisateur: employe_nom
        });
        await log.save();

        res.redirect('/');
    } catch (err) {
        res.status(500).send("Erreur lors de la réservation.");
    }
});

// Supprimer une réservation (Accessible SEULEMENT aux Admins)
app.post('/api/supprimer/:id', checkAuth, async (req, res) => {
    if (req.user.role !== 'admin') {
        return res.status(403).send("Accès refusé. Réservé aux administrateurs.");
    }

    const { id } = req.params;
    try {
        // Obtenir d'abord les infos de la réservation pour les logs IoT
        const getRes = await pool.query('SELECT * FROM reservations WHERE id = $1', [id]);

        if (getRes.rows.length > 0) {
            const resToDelete = getRes.rows[0];

            await pool.query('DELETE FROM reservations WHERE id = $1', [id]);

            const log = new IotLog({
                salle_nom: resToDelete.salle_nom,
                action: 'Suppression',
                utilisateur: req.user.username
            });
            await log.save();
        }
        res.redirect('/');
    } catch (err) {
        console.error(err);
        res.status(500).send("Erreur lors de la suppression.");
    }
});

// ==========================================
// 5. RENDU DU FRONTEND (UI)
// ==========================================
app.get('/', async (req, res) => {
    const userSession = req.cookies.session ? JSON.parse(req.cookies.session) : null;

    // --- Si l'utilisateur n'est pas connecté --> Page de Login ---
    if (!userSession) {
        return res.send(`
        <!DOCTYPE html>
        <html lang="fr">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Connexion - Smart Office</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
            <style>body { background-color: #f8f9fa; display: flex; align-items: center; justify-content: center; height: 100vh; }</style>
        </head>
        <body>
            <div class="card shadow border-0" style="width: 400px;">
                <div class="card-body p-5">
                    <h3 class="text-center text-primary mb-4">Smart Office 2.0</h3>
                    <p class="text-center text-muted small mb-4">Connectez-vous pour accéder aux réservations.</p>
                    <form action="/login" method="POST">
                        <div class="mb-3">
                            <label class="form-label">Nom d'utilisateur</label>
                            <input type="text" class="form-control" name="username" required placeholder="admin ou employe">
                        </div>
                        <div class="mb-4">
                            <label class="form-label">Mot de passe</label>
                            <input type="password" class="form-control" name="password" required placeholder="admin123 ou employe123">
                        </div>
                        <button type="submit" class="btn btn-primary w-100 mb-3">Se connecter</button>
                    </form>
                    <div class="alert alert-secondary mb-0 p-2 text-center" style="font-size: 0.8em;">
                        <strong>Comptes PoC (Test) :</strong><br>
                        Admin : <code>admin</code> / <code>admin123</code><br>
                        User : <code>employe</code> / <code>employe123</code>
                    </div>
                </div>
            </div>
        </body>
        </html>
        `);
    }

    // --- Si l'utilisateur est connecté --> Dashboard Principal ---
    let reservationsHtml = '';
    let iotLogsHtml = '';

    try {
        const pgResult = await pool.query('SELECT * FROM reservations ORDER BY date_reservation DESC LIMIT 10');
        if (pgResult.rows.length === 0) {
            reservationsHtml = '<p class="text-muted p-3">Aucune réservation pour le moment.</p>';
        } else {
            reservationsHtml = '<ul class="list-group list-group-flush">';
            pgResult.rows.forEach(row => {
                const date = new Date(row.date_reservation).toLocaleString('fr-FR');
                // Seul l'Admin peut voir le bouton Supprimer
                const deleteBtn = userSession.role === 'admin'
                    ? `<form action="/api/supprimer/${row.id}" method="POST" class="d-inline float-end"><button type="submit" class="btn btn-sm btn-outline-danger">Supprimer</button></form>`
                    : '';

                reservationsHtml += `
                <li class="list-group-item">
                    👔 <strong>${row.employe_nom}</strong> a réservé la salle <strong>${row.salle_nom}</strong> 
                    <br><small class="text-muted">${date}</small>
                    ${deleteBtn}
                </li>`;
            });
            reservationsHtml += '</ul>';
        }
    } catch (err) { }

    try {
        const mongoResult = await IotLog.find().sort({ timestamp: -1 }).limit(10);
        if (mongoResult.length === 0) {
            iotLogsHtml = '<p class="text-muted p-3">Aucun log IoT reçu.</p>';
        } else {
            iotLogsHtml = '<ul class="list-group list-group-flush" style="font-family: monospace; font-size: 0.85em;">';
            mongoResult.forEach(log => {
                const date = new Date(log.timestamp).toLocaleTimeString('fr-FR');
                const actionColor = log.action === 'Suppression' ? 'text-danger' : 'text-success';
                iotLogsHtml += `<li class="list-group-item bg-light">📡 [${date}] <strong>${log.salle_nom}</strong> - <span class="${actionColor}">${log.action}</span> (Par: ${log.utilisateur})</li>`;
            });
            iotLogsHtml += '</ul>';
        }
    } catch (err) { }

    res.send(`
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Dashboard - Smart Office 2.0</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body class="bg-light">
        <nav class="navbar navbar-expand-lg navbar-dark bg-primary mb-4 p-3 shadow">
            <div class="container-fluid align-items-center">
                <a class="navbar-brand fw-bold" href="#">🏢 Smart Office 2.0</a>
                <div class="d-flex align-items-center text-white">
                    <span class="me-3">Connecté en tant que <strong>${userSession.username}</strong> (${userSession.role === 'admin' ? '🛡️ Admin' : '👤 Utilisateur'})</span>
                    <a href="/logout" class="btn btn-sm btn-light">Déconnexion</a>
                </div>
            </div>
        </nav>

        <div class="container">
            <div class="row">
                <div class="col-lg-6 mb-4">
                    <div class="card shadow-sm border-0 border-top border-primary border-4 mb-4">
                        <div class="card-header bg-white"><h5 class="mb-0">Effectuer une réservation</h5></div>
                        <div class="card-body">
                            <form action="/api/reserver" method="POST">
                                <div class="mb-3">
                                    <label class="form-label">Salle de réunion</label>
                                    <select class="form-select" name="salle_nom">
                                        <option value="Salle Da Vinci">Salle Da Vinci</option>
                                        <option value="Salle Lovelace">Salle Lovelace</option>
                                        <option value="Salle Turing">Salle Turing</option>
                                    </select>
                                </div>
                                <button type="submit" class="btn btn-primary w-100">Réserver la salle</button>
                            </form>
                        </div>
                    </div>

                    <div class="card shadow-sm border-0">
                        <div class="card-header bg-white">
                            <h5 class="mb-0">Tableau des Réservations (SQL)</h5>
                            <small class="text-muted">Géré via PostgreSQL</small>
                        </div>
                        <div class="card-body p-0">
                            ${reservationsHtml}
                        </div>
                    </div>
                </div>

                <div class="col-lg-6">
                    <div class="card shadow-sm border-0 border-top border-success border-4 h-100">
                        <div class="card-header bg-white">
                            <h5 class="mb-0">Flux de Logs & Sécurité (NoSQL)</h5>
                            <small class="text-muted">Géré via MongoDB en Time-Series</small>
                        </div>
                        <div class="card-body p-0">
                            ${iotLogsHtml}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
    </html>
    `);
});

app.listen(port, () => {
    console.log(`Serveur web Application Démarré sur le port ${port}`);
});
