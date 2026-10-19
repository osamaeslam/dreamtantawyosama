const fs = require('fs');
const path = require('path');
const { encode } = require('fast-png');

function createIcon(width, height, isMaskable = false) {
  const data = new Uint8Array(width * height * 4);
  const cx = width / 2;
  const cy = height / 2;
  
  // Outer radius: for maskable, stay within 80% safe zone (radius 0.38 of min dimension)
  const maxR = isMaskable ? width * 0.38 : width * 0.44;
  const innerR = maxR * 0.88;

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = (y * width + x) * 4;
      const dx = x - cx;
      const dy = y - cy;
      const dist = Math.sqrt(dx * dx + dy * dy);

      // Default background: deep slate 950 #0f172a
      let r = 15;
      let g = 23;
      let b = 42;
      let a = 255;

      // Outer emblem circle / squircle
      if (dist <= maxR) {
        // Gradient from royal blue (37, 99, 235) to indigo (67, 56, 202)
        const factor = (y / height);
        r = Math.round(37 * (1 - factor) + 30 * factor);
        g = Math.round(99 * (1 - factor) + 58 * factor);
        b = Math.round(235 * (1 - factor) + 138 * factor);

        // Gold border ring at edge
        if (dist >= innerR) {
          r = 245;
          g = 158;
          b = 11;
        }

        // Center badge: stylized "T" / "ط" geometric shape
        // Horizontal bar
        const barY = cy - height * 0.08;
        const barH = height * 0.07;
        const barW = width * 0.36;
        if (Math.abs(y - barY) <= barH / 2 && Math.abs(x - cx) <= barW / 2) {
          r = 255;
          g = 255;
          b = 255;
        }

        // Vertical stem
        const stemX = cx;
        const stemW = width * 0.08;
        const stemTop = barY;
        const stemBottom = cy + height * 0.18;
        if (x >= stemX - stemW / 2 && x <= stemX + stemW / 2 && y >= stemTop && y <= stemBottom) {
          r = 255;
          g = 255;
          b = 255;
        }

        // Base plate (curved loop for Arabic Ta "ط")
        const loopCx = cx - width * 0.05;
        const loopCy = cy + height * 0.12;
        const loopR = height * 0.12;
        const loopDist = Math.sqrt((x - loopCx) ** 2 + (y - loopCy) ** 2);
        if (loopDist <= loopR && loopDist >= loopR - height * 0.05 && x <= cx + width * 0.12) {
          r = 255;
          g = 255;
          b = 255;
        }

        // Gold accent star/dot
        const dotCx = cx + width * 0.12;
        const dotCy = cy - height * 0.16;
        const dotDist = Math.sqrt((x - dotCx) ** 2 + (y - dotCy) ** 2);
        if (dotDist <= height * 0.04) {
          r = 245;
          g = 158;
          b = 11;
        }
      }

      data[idx] = r;
      data[idx + 1] = g;
      data[idx + 2] = b;
      data[idx + 3] = a;
    }
  }

  return encode({ width, height, data });
}

const publicDir = path.join(__dirname, '..', 'public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}

// 1. 192x192
const pwa192 = createIcon(192, 192, false);
fs.writeFileSync(path.join(publicDir, 'pwa-192x192.png'), pwa192);
console.log('Created pwa-192x192.png');

// 2. 512x512
const pwa512 = createIcon(512, 512, false);
fs.writeFileSync(path.join(publicDir, 'pwa-512x512.png'), pwa512);
console.log('Created pwa-512x512.png');

// 3. 512x512 Maskable
const pwaMaskable = createIcon(512, 512, true);
fs.writeFileSync(path.join(publicDir, 'pwa-maskable-512x512.png'), pwaMaskable);
console.log('Created pwa-maskable-512x512.png');

// 4. Apple Touch Icon 180x180
const appleIcon = createIcon(180, 180, false);
fs.writeFileSync(path.join(publicDir, 'apple-touch-icon.png'), appleIcon);
console.log('Created apple-touch-icon.png');
