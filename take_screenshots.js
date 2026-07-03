const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

(async () => {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1200, height: 900 });

  const htmlPath = path.resolve('Dossier_Final_SmartOffice2.html');
  await page.goto('file:///' + htmlPath.replace(/\\/g, '/'), {
    waitUntil: 'networkidle0',
    timeout: 60000
  });

  // Wait for Mermaid
  try {
    await page.waitForSelector('pre.mermaid svg', { timeout: 10000 });
  } catch (e) {}
  await new Promise(r => setTimeout(r, 3000));

  const outDir = path.resolve('screenshots');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  // Cover page
  await page.screenshot({ path: path.join(outDir, '01_cover.png'), fullPage: false });
  console.log('Screenshot 1: Cover page');

  // Scroll to TOC
  await page.evaluate(() => {
    const toc = document.querySelector('.toc-page');
    if (toc) toc.scrollIntoView();
  });
  await new Promise(r => setTimeout(r, 500));
  await page.screenshot({ path: path.join(outDir, '02_toc.png'), fullPage: false });
  console.log('Screenshot 2: Table of contents');

  // Scroll to first section header bar
  await page.evaluate(() => {
    const bar = document.querySelector('.section-header-bar');
    if (bar) bar.scrollIntoView();
  });
  await new Promise(r => setTimeout(r, 500));
  await page.screenshot({ path: path.join(outDir, '03_section_header.png'), fullPage: false });
  console.log('Screenshot 3: Section header bar');

  // Scroll to first table
  await page.evaluate(() => {
    const tables = document.querySelectorAll('table');
    if (tables.length > 1) tables[1].scrollIntoView();
  });
  await new Promise(r => setTimeout(r, 500));
  await page.screenshot({ path: path.join(outDir, '04_table.png'), fullPage: false });
  console.log('Screenshot 4: Table');

  // Scroll to first Mermaid diagram
  await page.evaluate(() => {
    const m = document.querySelector('pre.mermaid svg');
    if (m) m.scrollIntoView();
  });
  await new Promise(r => setTimeout(r, 500));
  await page.screenshot({ path: path.join(outDir, '05_mermaid.png'), fullPage: false });
  console.log('Screenshot 5: Mermaid diagram');

  // Scroll to another Mermaid (2nd one)
  await page.evaluate(() => {
    const svgs = document.querySelectorAll('pre.mermaid svg');
    if (svgs.length > 1) svgs[1].scrollIntoView();
  });
  await new Promise(r => setTimeout(r, 500));
  await page.screenshot({ path: path.join(outDir, '06_mermaid2.png'), fullPage: false });
  console.log('Screenshot 6: Mermaid diagram 2');

  await browser.close();
  console.log('All screenshots saved to ./screenshots/');
})();
