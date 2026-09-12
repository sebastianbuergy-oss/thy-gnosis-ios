// Preflight for the bundled Thy Gnosis app: every file the WKWebView shell
// needs must exist, every local asset the page references must ship, the
// inline script must parse, the feed must be valid JSON, and the project
// must still point at the right bundle id.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const child = require('node:child_process');

const root = path.resolve(__dirname, '..');
const required = [
  'project.yml', 'codemagic.yaml', 'feed/feed.json',
  'web/index.html', 'web/fonts/fonts.css',
  'web/img/logo.png', 'web/img/symbol.png', 'web/img/texture.jpg', 'web/img/band.jpg',
  'web/img/cover-dov.jpg', 'web/img/cover-br.jpg', 'web/img/cover-sero.jpg',
  'App/AppDelegate.swift', 'App/WebViewController.swift', 'App/PrivacyInfo.xcprivacy',
  'App/Assets.xcassets/AppIcon.appiconset/Icon-1024.png'
];
const issues = [];
const read = rel => fs.readFileSync(path.join(root, rel), 'utf8');
for (const f of required) if (!fs.existsSync(path.join(root, f))) issues.push(`Missing ${f}`);

if (!issues.length) {
  const html = read('web/index.html');
  for (const m of html.matchAll(/(?:src|href)="((?:img|fonts)\/[^"]+)"/g)) {
    if (m[1].includes('${')) continue; // built at runtime from the data arrays, checked below
    if (!fs.existsSync(path.join(root, 'web', m[1]))) issues.push(`Referenced but missing: web/${m[1]}`);
  }
  for (const m of html.matchAll(/'([a-z0-9-]+\.(?:jpg|png))'/g)) {
    if (!fs.existsSync(path.join(root, 'web', 'img', m[1]))) issues.push(`Referenced but missing: web/img/${m[1]}`);
  }
  const css = read('web/fonts/fonts.css');
  for (const m of css.matchAll(/url\(([^)]+)\)/g)) {
    if (!fs.existsSync(path.join(root, 'web', 'fonts', m[1]))) issues.push(`Font missing: web/fonts/${m[1]}`);
  }
  if (html.includes('fonts.googleapis.com')) issues.push('index.html must use the bundled fonts, not Google Fonts.');
  if (!html.includes('viewport-fit=cover')) issues.push('index.html needs viewport-fit=cover for the notch.');
  const start = html.lastIndexOf('<script>'), end = html.lastIndexOf('</script>');
  if (start === -1 || end < start) issues.push('index.html has no inline script.');
  else {
    const tmp = path.join(os.tmpdir(), `thy-gnosis-${process.pid}.js`);
    fs.writeFileSync(tmp, html.slice(start + 8, end));
    try { child.execFileSync(process.execPath, ['--check', tmp], { stdio: 'pipe' }); }
    catch (e) { issues.push(`Inline script syntax: ${e.stderr?.toString().trim() || e.message}`); }
    fs.unlinkSync(tmp);
  }
  try {
    const feed = JSON.parse(read('feed/feed.json'));
    if (!Array.isArray(feed.upcoming) || !Array.isArray(feed.news)) issues.push('feed.json needs "upcoming" and "news" arrays.');
    for (const g of feed.upcoming || []) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(g.date || '')) issues.push(`feed.json gig without ISO date: ${JSON.stringify(g).slice(0, 80)}`);
    }
  } catch (e) { issues.push(`feed.json invalid: ${e.message}`); }
  const project = read('project.yml');
  if (!project.includes('PRODUCT_BUNDLE_IDENTIFIER: com.sebastianbuergy.thygnosis')) issues.push('project.yml bundle id changed.');
  if (!project.includes('CFBundleDisplayName: Thy Gnosis')) issues.push('project.yml display name changed.');
}

if (issues.length) { console.error(issues.join('\n')); process.exit(1); }
console.log('Preflight OK');
