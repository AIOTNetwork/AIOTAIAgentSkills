---
name: pixijs-hud
description: >
  Design and build responsive game HUD/UI for HTML5 games with PixiJS 8.x.
  Use when: creating game UI, heads-up displays, health bars, score displays,
  minimaps, inventory screens, dialog boxes, game menus, touch controls,
  mobile-friendly game interfaces, or responsive canvas layouts. Triggers on:
  game HUD, game UI, health bar, score display, minimap, inventory, dialog box,
  game menu, touch joystick, responsive game, screen scaling, safe area, anchor
  positioning, @pixi/ui, @pixi/layout, HUD layer, UI scaling, mobile game UI,
  resolution independent, adaptive layout, damage numbers, progress bar.
---

# PixiJS 8.x — Responsive Game HUD

Build game UI that works across screen sizes, resolutions, and devices.

## References

| File | When to Read |
|------|-------------|
| [references/hud-patterns.md](references/hud-patterns.md) | Building specific HUD components (health bar, minimap, dialog, inventory, joystick, damage numbers) |
| [references/scaling-layout.md](references/scaling-layout.md) | Screen scaling strategies, @pixi/layout flexbox, safe zones, resolution independence |

## HUD Architecture

Separate game rendering from UI with a layered approach:

```javascript
import { Application, Container } from 'pixi.js';

const app = new Application();
await app.init({ width: 1920, height: 1080, resizeTo: window });
document.body.appendChild(app.canvas);

// Layer structure
const gameWorld = new Container({ isRenderGroup: true });
const hudLayer = new Container({ isRenderGroup: true });
app.stage.addChild(gameWorld, hudLayer);
// hudLayer always renders on top, transforms independent of game camera
```

### Static vs Dynamic Separation

Split HUD into cached static elements and cheap dynamic elements:

```javascript
// Static: borders, backgrounds, decorations → cache as texture
const hudBackground = new Container();
hudBackground.addChild(panelBg, borders, icons);
hudBackground.cacheAsTexture(); // 1 draw call for all decorations

// Dynamic: scores, health values, timers → BitmapText (cheap updates)
const hudDynamic = new Container();
const scoreText = new BitmapText({ text: '0', style: { fontFamily: 'GameFont', fontSize: 32 } });
const healthText = new BitmapText({ text: '100', style: { fontFamily: 'GameFont', fontSize: 24 } });
hudDynamic.addChild(scoreText, healthText);

hudLayer.addChild(hudBackground, hudDynamic);
```

**Rule:** Never put frequently-changing text inside a `cacheAsTexture()` container — it defeats the purpose. Use BitmapText in the dynamic layer.

## Screen Scaling

Design at a reference resolution, compute a scale factor, apply to all HUD elements.

```javascript
const DESIGN_W = 1920;
const DESIGN_H = 1080;

function getScaleFactor(screenW, screenH) {
  return Math.min(screenW / DESIGN_W, screenH / DESIGN_H);
}

function resize() {
  const w = app.screen.width;
  const h = app.screen.height;
  const scale = getScaleFactor(w, h);
  hud.resize(w, h, scale);
}

window.addEventListener('resize', resize);
resize();
```

Three scaling strategies — see [references/scaling-layout.md](references/scaling-layout.md):

| Strategy | When to Use |
|----------|------------|
| **Scale Factor** | Most games — design at 1920x1080, scale uniformly |
| **Letterbox** | Pixel art / retro — fixed aspect ratio, black bars |
| **Viewport Fill** | Flexible aspect ratio — renderer matches window exactly |

## Anchor-Based Positioning

Pin HUD elements to screen edges. Recalculate on every resize.

```
┌─[Score]────────────────────[Pause]─┐
│                                     │
│            GAME WORLD               │
│                                     │
│ [Ammo]                    [Minimap] │
└────────────[Controls]───────────────┘
```

```javascript
const MARGIN = 16;

class HUD extends Container {
  constructor() {
    super();
    this.score = new BitmapText({ text: 'Score: 0', style: { fontFamily: 'GameFont', fontSize: 32 } });
    this.pauseBtn = createPauseButton();
    this.healthBar = createHealthBar();
    this.minimap = createMinimap();
    this.addChild(this.score, this.pauseBtn, this.healthBar, this.minimap);
  }

  resize(w, h, scale) {
    const m = MARGIN * scale;
    // Top-left
    this.score.position.set(m, m);
    this.score.scale.set(scale);
    // Top-right
    this.pauseBtn.position.set(w - this.pauseBtn.width * scale - m, m);
    this.pauseBtn.scale.set(scale);
    // Bottom-left
    this.healthBar.position.set(m, h - this.healthBar.height * scale - m);
    this.healthBar.scale.set(scale);
    // Bottom-right
    this.minimap.position.set(w - this.minimap.width * scale - m, h - this.minimap.height * scale - m);
    this.minimap.scale.set(scale);
  }
}
```

## Touch-Friendly Sizing

Minimum touch target: **48x48 CSS pixels**. Account for device pixel ratio.

```javascript
const MIN_TOUCH = 48;
const dpr = Math.min(window.devicePixelRatio, 2); // cap at 2

function ensureTouchSize(element, scale) {
  const minPx = MIN_TOUCH * dpr;
  const actualW = element.width * scale;
  const actualH = element.height * scale;
  if (actualW < minPx || actualH < minPx) {
    const touchScale = minPx / Math.min(actualW, actualH);
    element.scale.set(scale * touchScale);
  }
}
```

Minimum 8px spacing between adjacent touch targets.

## Safe Zones (Notched Displays)

Read device insets for iPhone notch, Android cutouts, home indicators:

```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

```javascript
function getSafeInsets() {
  const style = getComputedStyle(document.documentElement);
  return {
    top: parseInt(style.getPropertyValue('env(safe-area-inset-top)')) || 0,
    bottom: parseInt(style.getPropertyValue('env(safe-area-inset-bottom)')) || 0,
    left: parseInt(style.getPropertyValue('env(safe-area-inset-left)')) || 0,
    right: parseInt(style.getPropertyValue('env(safe-area-inset-right)')) || 0,
  };
}

// Apply to HUD margins
function resize(w, h, scale) {
  const insets = getSafeInsets();
  const m = MARGIN * scale;
  score.position.set(insets.left + m, insets.top + m);
  pauseBtn.position.set(w - insets.right - pauseBtn.width * scale - m, insets.top + m);
}
```

**Gotcha:** Insets change between portrait and landscape — recalculate on every resize.

## @pixi/ui Quick Patterns

```bash
npm install @pixi/ui
```

```javascript
import { FancyButton, ProgressBar } from '@pixi/ui';

// Button with hover/press states
const btn = new FancyButton({
  defaultView: new Graphics().roundRect(0, 0, 150, 50, 8).fill(0x3366ff),
  hoverView: new Graphics().roundRect(0, 0, 150, 50, 8).fill(0x4477ff),
  pressedView: new Graphics().roundRect(0, 0, 150, 50, 8).fill(0x2255dd),
  text: new BitmapText({ text: 'Start', style: { fontFamily: 'GameFont', fontSize: 24 } }),
});
btn.onPress.connect(() => { /* handle */ });

// Health bar
const healthBar = new ProgressBar({
  bg: new Graphics().roundRect(0, 0, 200, 20, 4).fill(0x333333),
  fill: new Graphics().roundRect(0, 0, 200, 20, 4).fill(0x22cc44),
  progress: 100,
});
healthBar.progress = 75; // update to 75%
```

## @pixi/layout for Menus

```bash
npm install @pixi/layout
```

Use for complex layouts (menus, settings, inventory grids). See [references/scaling-layout.md](references/scaling-layout.md) for full patterns.

```javascript
import { LayoutContainer } from '@pixi/layout';

const menu = new LayoutContainer({
  flexDirection: 'column',
  justifyContent: 'center',
  alignItems: 'center',
  gap: 16,
  width: 400,
  height: 600,
});
menu.addChild(titleText, startBtn, settingsBtn, quitBtn);
```

## Performance Rules

| Rule | Why |
|------|-----|
| Use `isRenderGroup: true` on HUD container | Isolates HUD from game world transforms |
| Cache static HUD with `cacheAsTexture()` | Reduces many decorative elements to 1 draw call |
| Use BitmapText for dynamic values | ~100x faster updates than canvas Text |
| Update minimap every 5-10 frames, not every frame | RenderTexture update is expensive |
| Pool damage numbers / floating text | Avoid create/destroy per hit |
| Separate static and dynamic into sibling containers | Only dynamic layer redraws each frame |
| Cap `devicePixelRatio` at 2 | Prevents GPU memory explosion on 3x+ displays |
