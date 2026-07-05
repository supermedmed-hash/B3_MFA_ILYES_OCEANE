const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');
const marked = require('marked');

async function generatePDF() {
    console.log('Lecture des fichiers Markdown...');
    const demoContent = fs.readFileSync(path.join(__dirname, 'docs', 'procedures', 'Guide_Soutenance_Demo.md'), 'utf-8');
    const qaContent = fs.readFileSync(path.join(__dirname, 'docs', 'procedures', 'Questions_Reponses_Jury.md'), 'utf-8');

    // Combine markdown
    const fullMarkdown = `
# Fiche de Révision - Soutenance Smart Office 2.0
> **Document Confidentiel Équipe B3** - Anti-sèche pour l'oral.

---

${demoContent}

<div style="page-break-before: always;"></div>

${qaContent}
    `;

    console.log('Conversion en HTML...');
    const htmlBody = marked.parse(fullMarkdown);

    const htmlContent = `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
            body { font-family: 'Inter', sans-serif; padding: 40px; color: #2C3E50; line-height: 1.6; }
            h1 { color: #2980B9; border-bottom: 2px solid #3498DB; padding-bottom: 10px; }
            h2 { color: #34495E; margin-top: 30px; }
            h3 { color: #16A085; }
            blockquote { background: #ECF0F1; border-left: 5px solid #BDC3C7; padding: 15px; font-style: italic; }
            code { background: #F4F6F6; padding: 2px 5px; border-radius: 4px; font-family: monospace; color: #E74C3C; }
            hr { border: 0; border-top: 1px solid #E5E7E9; margin: 30px 0; }
        </style>
    </head>
    <body>
        ${htmlBody}
    </body>
    </html>
    `;

    const htmlPath = path.join(__dirname, 'fiche_temp.html');
    fs.writeFileSync(htmlPath, htmlContent);

    console.log('Génération du PDF via Puppeteer...');
    const browser = await puppeteer.launch({ headless: 'new' });
    const page = await browser.newPage();
    await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), { waitUntil: 'networkidle0' });

    const pdfPath = path.join(__dirname, 'Fiche_Soutenance_SmartOffice.pdf');
    await page.pdf({
        path: pdfPath,
        format: 'A4',
        margin: { top: '20mm', bottom: '20mm', left: '20mm', right: '20mm' },
        printBackground: true
    });

    await browser.close();
    fs.unlinkSync(htmlPath);
    console.log('✅ PDF généré avec succès : ' + pdfPath);
}

generatePDF().catch(console.error);
