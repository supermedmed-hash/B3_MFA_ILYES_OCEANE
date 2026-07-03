const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

// ============================================================================
// 🖨️ PUPPETEER PDF RENDERER - SMART OFFICE 2.0
// Waits for Mermaid diagrams to fully render before printing
// ============================================================================

(async () => {
  console.log('🚀 Launching browser...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--font-render-hinting=none'    // Better font rendering
    ]
  });

  const page = await browser.newPage();

  // Set a wide viewport so Mermaid draws full-width diagrams
  await page.setViewport({ width: 1200, height: 800 });

  const htmlPath = path.resolve('Dossier_Final_SmartOffice2.html');

  if (!fs.existsSync(htmlPath)) {
    console.error('❌ HTML file not found: ' + htmlPath);
    await browser.close();
    process.exit(1);
  }

  console.log('📄 Loading HTML...');
  await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), {
    waitUntil: 'networkidle2',
    timeout: 90000
  });

  // Wait for Mermaid SVGs to appear in DOM
  console.log('⏳ Waiting for Mermaid diagrams to render...');
  try {
    await page.waitForSelector('pre.mermaid svg', { timeout: 15000 });
    console.log('   ✅ Mermaid SVGs detected in DOM');
  } catch (e) {
    console.log('   ⚠️  No Mermaid SVGs found (may be OK if diagrams are absent)');
  }

  // Extra safety delay for complex diagrams
  console.log('   ⏳ Extra 3s stabilization delay...');
  await new Promise(r => setTimeout(r, 3000));

  const pdfPath = path.resolve('Dossier Final - Smart Office 2.0.pdf');

  console.log('🖨️  Generating PDF...');
  await page.pdf({
    path: pdfPath,
    format: 'A4',
    printBackground: true,
    preferCSSPageSize: false,
    displayHeaderFooter: true,
    headerTemplate: `
      <div style="width:100%; padding: 0 18mm; font-size: 7pt; font-family: Inter, Arial, sans-serif; color: #AEB6BF; display: flex; justify-content: space-between;">
        <span>Smart Office 2.0 — Dossier d'Architecture Technique</span>
        <span>Confidentiel</span>
      </div>
    `,
    footerTemplate: `
      <div style="width:100%; padding: 0 18mm; font-size: 7.5pt; font-family: Inter, Arial, sans-serif; color: #AEB6BF; display: flex; justify-content: space-between;">
        <span>Projet B3 — Ynov Campus · Biotech Corp</span>
        <span>Page <span class="pageNumber"></span> / <span class="totalPages"></span></span>
      </div>
    `,
    margin: {
      top: '22mm',
      bottom: '20mm',
      left: '18mm',
      right: '18mm'
    }
  });

  await browser.close();

  const stats = fs.statSync(pdfPath);
  const sizeMB = (stats.size / (1024 * 1024)).toFixed(2);
  console.log(`✅ PDF généré avec succès ! (${sizeMB} Mo)`);
  console.log(`   📁 ${pdfPath}`);
})();
