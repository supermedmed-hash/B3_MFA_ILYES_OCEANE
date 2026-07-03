const fs = require('fs');
const path = require('path');
const { parse } = require('marked');

// ============================================================================
// 🏗️ BUILD SCRIPT - DOSSIER FINAL SMART OFFICE 2.0
// Generates a premium, print-ready HTML document for PDF export
// ============================================================================

const filesToInclude = [
    { title: "Dossier d'Architecture Technique (DAT)", path: 'docs/dat/DAT_SmartOffice2.html' },
    { title: "Architecture Physique", path: 'docs/schemas/schema_physique.md' },
    { title: "Plan d'Adressage IP et VLANs", path: 'docs/schemas/plan_adressage_biotech.md' },
    { title: "Matrice des Flux Réseau", path: 'docs/schemas/matrice_flux_reseau.md' },
    { title: "Architecture Wi-Fi", path: 'docs/dat/architecture_wifi.md' },
    { title: "Analyse Comparative Cloud et TCO", path: 'docs/dat/analyse_comparative_cloud.md' },
    { title: "Architecture Hybride Détaillée", path: 'docs/schemas/architecture_hybride_detaillee.md' },
    { title: "Modèle de Données UML / Merise", path: 'docs/schemas/modele_donnees_UML.md' },
    { title: "Stratégie de Stockage et Sauvegarde", path: 'docs/dat/strategie_stockage.md' },
    { title: "Politique de Sécurité (PSSI)", path: 'docs/procedures/politique_securite.html' },
    { title: "Analyse d'Impact sur l'Activité (BIA)", path: 'docs/procedures/analyse_BIA.html' },
    { title: "Plan de Continuité et Reprise (PCA/PRA)", path: 'docs/procedures/PCA_PRA_SmartOffice2.html' },
    { title: "Processus ITSM — Gestion des Incidents", path: 'docs/procedures/processus_ITSM.html' },
    { title: "Architecture de Supervision (Zabbix & Grafana)", path: 'docs/dat/supervision_monitoring.md' },
    { title: "Démarche DevOps et Déploiement CI/CD", path: 'docs/procedures/strategie_deploiement_azure.md' },
    { title: "Suivi Agile et Sprints", path: 'docs/gestion-projet/suivi_sprints.md' }
];

// ============================================================================
// PREMIUM STYLESHEET — works on screen AND print
// ============================================================================
const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');

/* ===== RESET & BASE ===== */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

:root {
    --c-primary: #0F2B46;
    --c-accent: #1B6CA8;
    --c-accent-light: #2E86C1;
    --c-accent-bg: #EBF5FB;
    --c-border: #D5DBDB;
    --c-text: #2C3E50;
    --c-text-light: #5D6D7E;
    --c-bg-even: #F8F9FA;
    --c-danger: #C0392B;
    --c-success: #27AE60;
    --radius: 6px;
    --content-max: 900px;
}

html { font-size: 14px; }

body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    line-height: 1.7;
    color: var(--c-text);
    background: #F0F2F5;
    margin: 0;
    padding: 0;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
}

/* ===== PRINT RULES ===== */
@page {
    size: A4;
    margin: 18mm 16mm 20mm 16mm;
}

@page :first { margin: 0; }

@media print {
    body { background: white; }
    .cover-page { width: 210mm; height: 297mm; }
}

h1, h2, h3, h4 { page-break-after: avoid; break-after: avoid; }
table, pre, .mermaid, .highlight, blockquote, .link-card, .alert, .rule-box {
    page-break-inside: avoid; break-inside: avoid;
}
tr { page-break-inside: avoid; break-inside: avoid; }
p, li { orphans: 3; widows: 3; }
h1 + *, h2 + *, h3 + *, h4 + * { page-break-before: avoid; break-before: avoid; }

/* ===== COVER PAGE (SOBER CORPORATE) ===== */
.cover-page {
    width: 100%;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
    background: #ffffff;
    color: var(--c-primary);
    padding: 60px 40px;
    position: relative;
    page-break-after: always;
    break-after: page;
}

.cover-logo {
    width: 250px;
    max-width: 80%;
    margin-bottom: 50px;
}

.cover-page h1 {
    font-size: 46px;
    font-weight: 800;
    letter-spacing: -1px;
    color: var(--c-primary);
    margin: 0 0 12px 0;
    border: none;
}

.cover-subtitle {
    font-size: 18px;
    font-weight: 400;
    color: var(--c-text-light);
    letter-spacing: 2px;
    text-transform: uppercase;
    margin: 0 0 40px 0;
}

.cover-divider {
    width: 60px;
    height: 4px;
    background: var(--c-accent);
    margin: 0 auto 40px auto;
}

.cover-meta {
    text-align: left;
    font-size: 15px;
    line-height: 2.2;
    color: var(--c-text);
    border-top: 1px solid var(--c-border);
    border-bottom: 1px solid var(--c-border);
    padding: 30px 40px;
    width: 100%;
    max-width: 550px;
}

.cover-meta strong {
    font-weight: 600;
    color: var(--c-primary);
    display: inline-block;
    width: 130px;
}

.cover-footer {
    position: absolute;
    bottom: 40px;
    font-size: 12px;
    color: var(--c-text-light);
    letter-spacing: 0.5px;
}

/* ===== TABLE OF CONTENTS ===== */
.toc-page {
    max-width: var(--content-max);
    margin: 0 auto;
    padding: 48px 32px 40px;
    page-break-after: always;
    break-after: page;
}

.toc-page h1 {
    font-size: 28px;
    font-weight: 800;
    color: var(--c-primary);
    margin: 0 0 8px 0;
    border: none;
}

.toc-underline {
    width: 60px;
    height: 3px;
    background: var(--c-accent);
    border-radius: 2px;
    margin-bottom: 28px;
}

.toc-list {
    list-style: none;
    padding: 0;
    margin: 0;
}

.toc-item {
    display: flex;
    align-items: center;
    padding: 10px 14px;
    border-radius: var(--radius);
    transition: background 0.15s;
    gap: 12px;
}

.toc-item:hover { background: var(--c-accent-bg); }

.toc-item:nth-child(even) { background: var(--c-bg-even); }
.toc-item:nth-child(even):hover { background: #e0ecf5; }

.toc-icon {
    font-size: 18px;
    flex-shrink: 0;
    width: 28px;
    text-align: center;
}

.toc-num {
    font-weight: 700;
    color: var(--c-accent);
    font-size: 13px;
    min-width: 24px;
    flex-shrink: 0;
}

.toc-title {
    font-weight: 500;
    font-size: 14px;
    color: var(--c-text);
}

/* ===== SECTION WRAPPER ===== */
.section-block {
    max-width: var(--content-max);
    margin: 0 auto;
    padding: 0 32px 40px;
    page-break-before: always;
    break-before: page;
}

/* ===== SECTION HEADER BAR ===== */
.section-header-bar {
    background: linear-gradient(135deg, var(--c-primary) 0%, var(--c-accent) 100%);
    color: white;
    padding: 18px 28px;
    border-radius: 8px;
    margin-bottom: 32px;
    display: flex;
    align-items: center;
    gap: 16px;
    box-shadow: 0 3px 12px rgba(15,43,70,0.15);
}

.sec-icon { font-size: 28px; flex-shrink: 0; }

.sec-num {
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 2px;
    opacity: 0.65;
    margin-bottom: 2px;
}

.sec-title {
    font-size: 20px;
    font-weight: 700;
    line-height: 1.3;
}

/* ===== CONTENT TYPOGRAPHY ===== */
.section-content {
    font-size: 13.5px;
    line-height: 1.7;
}

/* Kill duplicate headers from injected HTML sub-docs */
.section-content > h1:first-child,
.section-content > .container > .header,
.section-content > .container > h1:first-child {
    display: none;
}

.section-content .container { max-width: 100% !important; padding: 0 !important; }

.section-content h1 {
    font-size: 22px;
    font-weight: 800;
    color: var(--c-primary);
    margin: 36px 0 12px 0;
    padding-bottom: 8px;
    border-bottom: 2.5px solid var(--c-accent);
}

.section-content h2 {
    font-size: 17px;
    font-weight: 700;
    color: var(--c-accent);
    margin: 28px 0 10px 0;
    padding-bottom: 6px;
    border-bottom: 1.5px solid #D4E6F1;
}

.section-content h3 {
    font-size: 15px;
    font-weight: 600;
    color: var(--c-primary);
    margin: 22px 0 8px 0;
}

.section-content h4 {
    font-size: 14px;
    font-weight: 600;
    color: var(--c-text);
    margin: 18px 0 6px 0;
}

.section-content p {
    margin: 0 0 12px 0;
    text-align: justify;
    hyphens: auto;
}

.section-content ul, .section-content ol {
    margin: 8px 0 16px 0;
    padding-left: 24px;
}

.section-content li { margin-bottom: 6px; }

/* ===== TABLES ===== */
table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0 20px 0;
    font-size: 12.5px;
    border: 1px solid #DCE1E4;
    border-radius: var(--radius);
    overflow: hidden;
    box-shadow: 0 1px 4px rgba(0,0,0,0.04);
}

th {
    background: var(--c-primary);
    color: white;
    padding: 10px 14px;
    font-weight: 600;
    font-size: 11.5px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
    text-align: left;
    border: none;
}

td {
    padding: 9px 14px;
    border-bottom: 1px solid #EBF0F3;
    border-right: 1px solid #EBF0F3;
    vertical-align: top;
}

td:last-child { border-right: none; }
tr:nth-child(even) td { background: var(--c-bg-even); }
tr:last-child td { border-bottom: none; }
tr:hover td { background: #E8F0FE; }

/* BIA criticality badges */
.critical { background: #E74C3C !important; color: white; font-weight: 700; text-align: center; border-radius: 3px; }
.high { background: #F39C12 !important; color: white; font-weight: 700; text-align: center; }
.medium { background: #F1C40F !important; color: #333; font-weight: 700; text-align: center; }
.low { background: #27AE60 !important; color: white; font-weight: 700; text-align: center; }

/* ===== CALLOUT BOXES ===== */
.highlight {
    background: var(--c-accent-bg);
    border-left: 4px solid var(--c-accent-light);
    padding: 14px 20px;
    margin: 14px 0;
    border-radius: 0 var(--radius) var(--radius) 0;
    font-size: 13px;
}

.alert, .rule-box {
    background: #FDF2F2;
    border-left: 4px solid var(--c-danger);
    padding: 14px 20px;
    margin: 14px 0;
    border-radius: 0 var(--radius) var(--radius) 0;
    font-size: 13px;
    color: #922B21;
}

/* ===== LINK CARDS (from DAT HTML) ===== */
.link-card {
    display: none !important;
}

/* ===== CODE BLOCKS ===== */
pre:not(.mermaid) {
    background: #F7F9FA;
    border: 1px solid #E5E8E8;
    padding: 16px 20px;
    border-radius: var(--radius);
    font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
    font-size: 12px;
    line-height: 1.5;
    overflow-x: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
}

code {
    font-family: 'Consolas', 'Monaco', 'Courier New', monospace;
    font-size: 12px;
    background: #EBF5FB;
    padding: 2px 6px;
    border-radius: 3px;
    color: var(--c-accent);
}

pre code { background: none; padding: 0; color: inherit; }

/* ===== MERMAID DIAGRAMS ===== */
pre.mermaid {
    background: white !important;
    border: 1.5px solid #D5DBDB;
    border-radius: 8px;
    padding: 24px 16px;
    margin: 20px 0;
    text-align: center;
    overflow: visible;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}

pre.mermaid svg {
    max-width: 100% !important;
    height: auto !important;
}

/* ===== LINKS ===== */
a { color: var(--c-accent); text-decoration: none; font-weight: 600; }

/* ===== HIDE internal footers ===== */
.footer, .section-content > .container > .footer { display: none; }
.page-break { display: none; }

/* ===== HR ===== */
hr {
    border: none;
    border-top: 1.5px solid #E5E8E8;
    margin: 28px 0;
}

/* ===== BLOCKQUOTE ===== */
blockquote {
    border-left: 3px solid var(--c-accent-light);
    margin: 14px 0;
    padding: 10px 18px;
    background: var(--c-accent-bg);
    border-radius: 0 var(--radius) var(--radius) 0;
    font-style: italic;
    color: var(--c-text-light);
}

/* ===== RESPONSIVE for screen preview ===== */
@media screen {
    body { padding: 0; }
    .section-block { 
        background: white;
        margin: 24px auto;
        padding: 40px 48px;
        border-radius: 8px;
        box-shadow: 0 2px 16px rgba(0,0,0,0.06);
    }
    .toc-page {
        background: white;
        margin: 24px auto;
        padding: 40px 48px;
        border-radius: 8px;
        box-shadow: 0 2px 16px rgba(0,0,0,0.06);
    }
}
`;

// ============================================================================
// BUILD HTML
// ============================================================================

// Generate TOC items
let tocHtml = '';
filesToInclude.forEach((file, idx) => {
    tocHtml += `
        <li class="toc-item">
            <span class="toc-num">${String(idx + 1).padStart(2, '0')}</span>
            <span class="toc-title">${file.title}</span>
        </li>`;
});

let htmlContent = `<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dossier Final - Smart Office 2.0</title>
    <script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
      mermaid.initialize({
          startOnLoad: true,
          theme: 'base',
          themeVariables: {
              primaryColor: '#EBF5FB',
              primaryBorderColor: '#2980B9',
              primaryTextColor: '#0F2B46',
              lineColor: '#5D6D7E',
              secondaryColor: '#F8F9FA',
              tertiaryColor: '#FDEBD0',
              fontSize: '13px',
              fontFamily: 'Inter, sans-serif'
          },
          flowchart: { curve: 'basis', padding: 20 },
          securityLevel: 'loose'
      });
    </script>
    <style>${CSS}</style>
</head>
<body>

<!-- ==================== COVER PAGE ==================== -->
<div class="cover-page">
    <img src="./logo-ynov.png" alt="Ynov Campus" class="cover-logo">
    <h1>Smart Office 2.0</h1>
    <p class="cover-subtitle">Dossier d'Architecture Technique</p>
    <div class="cover-divider"></div>
    <div class="cover-meta">
        <div><strong>Projet :</strong> Infrastructure hybride sécurisée</div>
        <div><strong>Formation :</strong> Bachelor 3 Informatique</div>
        <div><strong>Spécialité :</strong> Infrastructure & Réseau</div>
        <div><strong>Équipe :</strong> Ilyes · Océane · Mehdi · Florian</div>
        <div><strong>Date :</strong> Juillet 2026</div>
    </div>
    <div class="cover-footer">Document interne — Biotech Corp & Ynov Campus</div>
</div>

<!-- ==================== TABLE OF CONTENTS ==================== -->
<div class="toc-page">
    <h1>Sommaire</h1>
    <div class="toc-underline"></div>
    <ul class="toc-list">
        ${tocHtml}
    </ul>
</div>

<!-- ==================== SECTIONS ==================== -->
`;

filesToInclude.forEach((file, idx) => {
    if (!fs.existsSync(file.path)) {
        console.warn('⚠️  File not found: ' + file.path);
        return;
    }
    const rawContent = fs.readFileSync(file.path, 'utf8');
    let sectionHtml = "";

    if (file.path.endsWith('.md')) {
        // Convert MD links to bold text
        let processedMd = rawContent.replace(/\[([^\]]+)\]\([^\)]+\)/g, '**$1**');

        // Extract Mermaid blocks before marked parsing
        let counter = 0;
        const mermaidBlocks = {};
        processedMd = processedMd.replace(/\`\`\`mermaid\r?\n([\s\S]*?)\`\`\`/g, (match, p1) => {
            const placeholder = `<div id="MERMAID_${idx}_${counter}"></div>`;
            mermaidBlocks[placeholder] = p1;
            counter++;
            return placeholder;
        });

        sectionHtml = parse(processedMd);

        // Re-inject Mermaid
        for (const [placeholder, content] of Object.entries(mermaidBlocks)) {
            sectionHtml = sectionHtml.replace(placeholder, `<pre class="mermaid">\n${content}\n</pre>`);
        }
    } else {
        // HTML files: extract body
        let bodyContent = rawContent;
        const bodyMatch = rawContent.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
        if (bodyMatch) {
            bodyContent = bodyMatch[1];
        }
        // Strip links → bold
        bodyContent = bodyContent.replace(/<a[^>]*>([\s\S]*?)<\/a>/gi, '<strong>$1</strong>');
        sectionHtml = bodyContent;
    }

    htmlContent += `
<!-- ==================== SECTION ${idx + 1}: ${file.title} ==================== -->
<div class="section-block">
    <div class="section-header-bar">
        <div>
            <div class="sec-num">Section ${String(idx + 1).padStart(2, '0')}</div>
            <div class="sec-title">${file.title}</div>
        </div>
    </div>
    <div class="section-content">
        ${sectionHtml}
    </div>
</div>
`;
});

htmlContent += `
</body>
</html>`;

fs.writeFileSync('Dossier_Final_SmartOffice2.html', htmlContent, 'utf8');
console.log('✅ Dossier_Final_SmartOffice2.html généré avec succès !');
