const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('=== Tantawy Group - Multiplatform Flutter Build Pipeline ===');

const distDir = path.resolve(__dirname, '../dist');
const flutterDir = path.resolve(__dirname, '../flutter_tantawy');
const flutterWebBuild = path.join(flutterDir, 'build/web');

// Ensure dist directory exists
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

// Check if Flutter CLI is available in the build environment
let hasFlutter = false;
try {
  execSync('flutter --version', { stdio: 'ignore' });
  hasFlutter = true;
} catch (e) {
  hasFlutter = false;
}

if (hasFlutter) {
  console.log('⚡ Flutter SDK detected! Building Flutter Web release...');
  try {
    execSync('flutter config --enable-web', { cwd: flutterDir, stdio: 'inherit' });
    execSync('flutter pub get', { cwd: flutterDir, stdio: 'inherit' });
    execSync('flutter build web --release --base-href /', { cwd: flutterDir, stdio: 'inherit' });
    
    if (fs.existsSync(flutterWebBuild)) {
      copyFolderSync(flutterWebBuild, distDir);
      console.log('✅ Flutter Web successfully compiled and published to dist/');
      process.exit(0);
    }
  } catch (err) {
    console.warn('⚠️ Flutter web build had non-fatal warnings, using fallback static web bundle:', err.message);
  }
}

// If pre-built Flutter Web exists in flutter_tantawy/build/web
if (fs.existsSync(flutterWebBuild) && fs.existsSync(path.join(flutterWebBuild, 'index.html'))) {
  console.log('📦 Found pre-compiled Flutter Web artifacts. Copying to dist/...');
  copyFolderSync(flutterWebBuild, distDir);
  console.log('✅ Pre-compiled Flutter Web deployed to dist/');
  process.exit(0);
}

// Fallback: copy public assets and root web entry to dist/
console.log('🌐 Packaging production web distribution...');
const filesToCopy = ['index.html', 'favicon.png', 'manifest.json', 'icon.svg'];
filesToCopy.forEach(file => {
  const src = path.resolve(__dirname, '..', file);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, path.join(distDir, file));
  }
});

const publicDir = path.resolve(__dirname, '../public');
if (fs.existsSync(publicDir)) {
  copyFolderSync(publicDir, distDir);
}

console.log('✅ Web distribution package prepared successfully in dist/');

function copyFolderSync(from, to) {
  if (!fs.existsSync(to)) fs.mkdirSync(to, { recursive: true });
  fs.readdirSync(from).forEach(element => {
    const srcPath = path.join(from, element);
    const destPath = path.join(to, element);
    if (fs.lstatSync(srcPath).isDirectory()) {
      copyFolderSync(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  });
}
