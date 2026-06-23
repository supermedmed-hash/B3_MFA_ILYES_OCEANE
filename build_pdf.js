const fs = require('fs');
const path = require('path');
const { parse } = require('marked');

const filesToInclude = [
    { title: "Dossier d'Architecture Technique (DAT)", path: 'docs/dat/DAT_SmartOffice2.html' },
    { title: "Architecture Physique", path: 'docs/schemas/schema_physique.md' },
    { title: "Architecture Hybride (Détail)", path: 'docs/schemas/architecture_hybride_detaillee.md' },
    { title: "Matrice des Flux Réseau", path: 'docs/schemas/matrice_flux_reseau.md' },
    { title: "Architecture Wi-Fi", path: 'docs/dat/architecture_wifi.md' },
    { title: "Analyse Comparative Cloud", path: 'docs/dat/analyse_comparative_cloud.md' },
    { title: "Modèle de Données", path: 'docs/schemas/modele_donnees_UML.md' },
    { title: "Stratégie de Stockage", path: 'docs/dat/strategie_stockage.md' },
    { title: "Politique de Sécurité (PSSI)", path: 'docs/procedures/politique_securite.html' },
    { title: "Analyse BIA", path: 'docs/procedures/analyse_BIA.html' },
    { title: "PCA / PRA", path: 'docs/procedures/PCA_PRA_SmartOffice2.html' },
    { title: "Processus ITSM", path: 'docs/procedures/processus_ITSM.html' }
];

let htmlContent = `<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Dossier Final - Smart Office 2.0</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
    <script type="module">
      import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
      mermaid.initialize({ startOnLoad: true });
    </script>
    <style>
        body { font-family: 'Inter', sans-serif; color: #333; line-height: 1.6; background-color: white; padding: 40px; margin: 0; }
        .container { max-width: 1000px; margin: auto; }
        .page-break { page-break-before: always; margin-top: 50px; }
        .cover { text-align: center; margin-top: 150px; page-break-after: always; }
        .cover h1 { font-size: 3em; color: #1a5276; }
        .cover h2 { font-size: 2em; color: #2980b9; }
        h1, h2, h3 { color: #1a5276; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #2980b9; color: white; }
        tr:nth-child(even) { background-color: #f2f4f4; }
        .highlight { background-color: #ebf5fb; border-left: 4px solid #3498db; padding: 15px; margin: 20px 0; }
        a { color: inherit; text-decoration: none; font-weight: bold; } /* Desactive liens cliquables visuellement */
        img { max-width: 100%; height: auto; }
        pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
<div class="container">
    <div class="cover">
        <h1>Projet Smart Office 2.0</h1>
        <h2>Dossier Consolidé de Soutenance</h2>
        <p><strong>Équipe B3</strong></p>
        <p><em>Généré pour export PDF</em></p>
    </div>
`;

filesToInclude.forEach(file => {
    if (fs.existsSync(file.path)) {
        const rawContent = fs.readFileSync(file.path, 'utf8');
        let sectionHtml = "";

        if (file.path.endsWith('.md')) {
            // Convertir les liens Markdown en texte brut avant parsing
            let processedMd = rawContent.replace(/\[([^\]]+)\]\([^\)]+\)/g, '**$1**');
            
            // Extraire les blocs mermaid pour éviter que marked les parse (et échappe les caractères >)
            let counter = 0;
            const mermaidBlocks = {};
            processedMd = processedMd.replace(/\`\`\`mermaid\r?\n([\s\S]*?)\`\`\`/g, (match, p1) => {
                const id = `___MERMAID_BLOCK_${counter++}___`;
                mermaidBlocks[id] = p1;
                return id;
            });
            
            sectionHtml = parse(processedMd);
            
            // Réinjecter les blocs mermaid en HTML brut
            for (const [id, content] of Object.entries(mermaidBlocks)) {
                sectionHtml = sectionHtml.replace(id, `<pre class="mermaid">\n${content}\n</pre>`);
            }
        } else {
            // Nettoyer les HTML
            let bodyContent = rawContent;
            const bodyMatch = rawContent.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
            if (bodyMatch) {
                bodyContent = bodyMatch[1];
            }
            // Enlever les liens
            bodyContent = bodyContent.replace(/<a[^>]*>([\s\S]*?)<\/a>/gi, '<strong>$1</strong>');
            sectionHtml = bodyContent;
        }

        htmlContent += `
    <div class="page-break"></div>
    <!-- SECTION: ${file.title} -->
    <div class="section-content">
        ${sectionHtml}
    </div>
        `;
    } else {
        console.warn('File not found: ' + file.path);
    }
});

htmlContent += `
</div>
</body>
</html>`;

fs.writeFileSync('Dossier_Final_SmartOffice2.html', htmlContent, 'utf8');
console.log('Fichier Dossier_Final_SmartOffice2.html généré avec succès !');
