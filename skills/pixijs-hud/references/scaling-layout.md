# PixiJS 8.x — Screen Scaling & Layout

## Table of Contents

- [Scaling Strategies](#scaling-strategies)
- [Resolution Independence](#resolution-independence)
- [Safe Zones for Notched Displays](#safe-zones-for-notched-displays)
- [Flexbox Layout with @pixi/layout](#flexbox-layout-with-pixilayout)
- [Responsive Patterns](#responsive-patterns)

---

## Scaling Strategies

### Scale Factor (Recommended for Most Games)

Design at a reference resolution. Compute a uniform scale factor. Apply to all UI elements.

```javascript
const DESIGN_W = 1920;
const DESIGN_H = 1080;

class ScaleManager {
  constructor(app) {
    this.app = app;
    this.scale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
  }

  resize() {
    const w = this.app.screen.width;
    const h = this.app.screen.height;

    // Fit inside screen maintaining aspect ratio
    this.scale = Math.min(w / DESIGN_W, h / DESIGN_H);

    // Center offset (for letterbox-like centering)
    this.offsetX = (w - DESIGN_W * this.scale) / 2;
    this.offsetY = (h - DESIGN_H * this.scale) / 2;

    return { scale: this.scale, offsetX: this.offsetX, offsetY: this.offsetY, w, h };
  }

  // Convert design coordinates to screen coordinates
  toScreen(x, y) {
    return {
      x: x * this.scale + this.offsetX,
      y: y * this.scale + this.offsetY,
    };
  }

  // Scale a dimension
  scalePx(px) {
    return Math.round(px * this.scale);
  }

  // Scale font size with minimum
  scaleFont(baseSize, min = 12) {
    return Math.max(Math.round(baseSize * this.scale), min);
  }
}
```

### Letterbox (Fixed Aspect Ratio)

Canvas stays at design resolution. CSS scales it to fit. Black bars fill unused space.

```javascript
const app = new Application();
await app.init({ width: 960, height: 540 });

function resize() {
  const containerW = window.innerWidth;
  const containerH = window.innerHeight;
  const scale = Math.min(containerW / 960, containerH / 540);
  app.canvas.style.width = `${960 * scale}px`;
  app.canvas.style.height = `${540 * scale}px`;
}

window.addEventListener('resize', resize);
resize();
```

```css
body { background: #000; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
canvas { image-rendering: pixelated; } /* for pixel art */
```

Best for: pixel art, retro games, fixed-screen puzzles.

### Viewport Fill (Flexible Aspect Ratio)

Renderer matches window exactly. HUD repositions on resize.

```javascript
const app = new Application();
await app.init({ resizeTo: window });

// Or manual:
function resize() {
  app.renderer.resize(window.innerWidth, window.innerHeight);
  hud.resize(window.innerWidth, window.innerHeight);
}
window.addEventListener('resize', resize);
```

Best for: infinite runners, open-world, any game that benefits from extra visible area.

---

## Resolution Independence

### Multi-Resolution Assets

Provide asset variants for different DPI tiers:

```
assets/
├── @1x/    # 720p, low-end mobile
├── @2x/    # 1080p, standard (default)
└── @4x/    # 4K, high-DPI desktop
```

Select at startup:

```javascript
function getAssetResolution() {
  const dpr = Math.min(window.devicePixelRatio, 2); // cap at 2
  const screenW = window.innerWidth * dpr;
  if (screenW <= 1280) return '1x';
  if (screenW <= 2560) return '2x';
  return '4x';
}

const tier = getAssetResolution();
await Assets.init({ basePath: `/assets/@${tier}/` });
```

### Font Scaling

```javascript
function scaledFontSize(baseSize, scaleFactor) {
  const scaled = Math.round(baseSize * scaleFactor);
  return Math.max(scaled, 10); // never below 10px
}

// For BitmapFont, install at the scaled size
BitmapFont.install({
  name: 'ScaledFont',
  style: { fontSize: scaledFontSize(32, scaleManager.scale), fill: 0xffffff },
});
```

---

## Safe Zones for Notched Displays

### HTML Setup (Required)

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

```css
:root {
  --sat: env(safe-area-inset-top, 0px);
  --sar: env(safe-area-inset-right, 0px);
  --sab: env(safe-area-inset-bottom, 0px);
  --sal: env(safe-area-inset-left, 0px);
}
```

### Reading Insets in JavaScript

```javascript
function getSafeInsets() {
  const root = document.documentElement;
  const computed = getComputedStyle(root);
  return {
    top: parseFloat(computed.getPropertyValue('--sat')) || 0,
    right: parseFloat(computed.getPropertyValue('--sar')) || 0,
    bottom: parseFloat(computed.getPropertyValue('--sab')) || 0,
    left: parseFloat(computed.getPropertyValue('--sal')) || 0,
  };
}
```

### Applying to HUD

```javascript
function positionWithSafeArea(element, anchor, screenW, screenH, margin = 16) {
  const insets = getSafeInsets();

  switch (anchor) {
    case 'top-left':
      element.position.set(insets.left + margin, insets.top + margin);
      break;
    case 'top-right':
      element.position.set(screenW - insets.right - element.width - margin, insets.top + margin);
      break;
    case 'bottom-left':
      element.position.set(insets.left + margin, screenH - insets.bottom - element.height - margin);
      break;
    case 'bottom-right':
      element.position.set(
        screenW - insets.right - element.width - margin,
        screenH - insets.bottom - element.height - margin,
      );
      break;
    case 'bottom-center':
      element.position.set(screenW / 2 - element.width / 2, screenH - insets.bottom - element.height - margin);
      break;
    case 'top-center':
      element.position.set(screenW / 2 - element.width / 2, insets.top + margin);
      break;
  }
}
```

### Common Inset Values

| Device | Top | Bottom | Left/Right (landscape) |
|--------|-----|--------|----------------------|
| iPhone 14/15 | 59px | 34px | 0px |
| iPhone 14/15 Pro | 59px | 34px | 0px |
| iPhone SE | 20px | 0px | 0px |
| Android (typical notch) | 48px | 0px | 0px |
| iPad | 20px | 0px | 0px |
| No notch | 0px | 0px | 0px |

**Important:** Always read dynamically — never hardcode. Insets differ portrait vs landscape.

---

## Flexbox Layout with @pixi/layout

```bash
npm install @pixi/layout
```

### Menu Screen

```javascript
import { LayoutContainer } from '@pixi/layout';
import { Graphics, BitmapText } from 'pixi.js';

function createMenuScreen(screenW, screenH) {
  const menu = new LayoutContainer({
    width: screenW,
    height: screenH,
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 24,
  });

  const title = new BitmapText({ text: 'GAME TITLE', style: { fontFamily: 'GameFont', fontSize: 64 } });
  const startBtn = createMenuButton('Start Game', 300, 60);
  const settingsBtn = createMenuButton('Settings', 300, 60);
  const creditsBtn = createMenuButton('Credits', 300, 60);

  menu.addChild(title, startBtn, settingsBtn, creditsBtn);

  menu.resize = function (w, h) {
    this.layout.width = w;
    this.layout.height = h;
  };

  return menu;
}

function createMenuButton(label, w, h) {
  const container = new LayoutContainer({ width: w, height: h, justifyContent: 'center', alignItems: 'center' });

  const bg = new Graphics().roundRect(0, 0, w, h, 8).fill(0x3355aa);
  const text = new BitmapText({ text: label, style: { fontFamily: 'GameFont', fontSize: 24 } });

  container.addChild(bg, text);
  container.eventMode = 'static';
  container.cursor = 'pointer';

  return container;
}
```

### Settings Panel (Two Columns)

```javascript
function createSettingsPanel(w, h) {
  const panel = new LayoutContainer({
    width: w,
    height: h,
    flexDirection: 'column',
    padding: 24,
    gap: 16,
  });

  function addRow(label, control) {
    const row = new LayoutContainer({
      width: w - 48,
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
    });
    const text = new BitmapText({ text: label, style: { fontFamily: 'GameFont', fontSize: 18 } });
    row.addChild(text, control);
    panel.addChild(row);
  }

  addRow('Music Volume', createSlider(0, 100, 80));
  addRow('SFX Volume', createSlider(0, 100, 100));
  addRow('Fullscreen', createToggle(false));

  return panel;
}
```

### HUD Bar (Top of Screen)

```javascript
function createTopHUDBar(screenW, scale) {
  const bar = new LayoutContainer({
    width: screenW,
    height: 60 * scale,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingLeft: 16 * scale,
    paddingRight: 16 * scale,
  });

  const healthBar = createHealthBar(100, 200 * scale, 20 * scale);
  const score = new BitmapText({ text: '0', style: { fontFamily: 'GameFont', fontSize: 32 * scale } });
  const pauseBtn = createPauseButton(40 * scale);

  bar.addChild(healthBar, score, pauseBtn);

  bar.onResize = function (w, s) {
    this.layout.width = w;
    this.layout.height = 60 * s;
    this.layout.paddingLeft = 16 * s;
    this.layout.paddingRight = 16 * s;
  };

  return bar;
}
```

---

## Responsive Patterns

### Breakpoint-Based Layout

Switch between mobile and desktop HUD layouts:

```javascript
function getLayoutMode(screenW) {
  if (screenW < 768) return 'mobile';
  if (screenW < 1200) return 'tablet';
  return 'desktop';
}

function resize(w, h) {
  const mode = getLayoutMode(w);

  switch (mode) {
    case 'mobile':
      joystick.visible = true;         // show virtual controls
      minimap.visible = false;          // hide minimap (too small)
      healthBar.width = w * 0.4;       // smaller health bar
      break;
    case 'tablet':
      joystick.visible = true;
      minimap.visible = true;
      minimap.scale.set(0.75);
      break;
    case 'desktop':
      joystick.visible = false;         // keyboard/mouse instead
      minimap.visible = true;
      minimap.scale.set(1);
      break;
  }
}
```

### Orientation Lock Suggestion

```javascript
function checkOrientation() {
  if (window.innerHeight > window.innerWidth) {
    // Show "rotate your device" overlay
    rotateOverlay.visible = true;
  } else {
    rotateOverlay.visible = false;
  }
}
window.addEventListener('resize', checkOrientation);
```

### Fullscreen Toggle

```javascript
function toggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen().catch(() => {});
  } else {
    document.exitFullscreen();
  }
}
```
