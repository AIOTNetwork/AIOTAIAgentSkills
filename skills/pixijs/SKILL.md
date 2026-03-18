---
name: pixijs
description: >
  Build high-performance HTML5 games with PixiJS 8.x (WebGL/WebGPU). Use when:
  developing browser games, 2D game engines, interactive applications, sprite
  animation, game loops, collision detection, tilemap rendering, scene management,
  or integrating game libraries (pixi-viewport, @pixi/sound, @pixi/tilemap, @pixi/ui,
  matter-js). Triggers on: pixi, pixijs, pixi.js, HTML5 game, browser game, web game,
  2D game, game loop, game state, scene graph, sprite sheet, texture atlas, collision,
  tilemap, camera follow, object pooling, particle system, WebGL, WebGPU, fixed timestep.
---

# PixiJS 8.x -- HTML5 Game Development

Build high-performance 2D browser games with PixiJS 8.x (WebGL2 / WebGPU).

## References

Read these on demand -- not upfront:

| File | When to read |
|------|-------------|
| [references/game-architecture.md](references/game-architecture.md) | Scene managers, state machines, ECS-lite patterns, save/load |
| [references/ecosystem.md](references/ecosystem.md) | Detailed setup for each ecosystem library |
| [references/performance.md](references/performance.md) | Deep optimization: batching, masks, filters, memory, mobile |
| [references/api-patterns.md](references/api-patterns.md) | Full API: shapes, text, assets, filters, interaction, Spine |
| [references/migration-v8.md](references/migration-v8.md) | v7-to-v8 breaking changes table |

---

## Game Project Setup

```bash
npm create pixi.js@latest            # scaffold (recommended)
# -- or existing project --
npm install pixi.js
npm install @pixi/sound               # audio
```

**Bundler**: Use Vite. Wrap bootstrap in an async function (avoid bare top-level await with Vite <= 6.0.6).

---

## Game Bootstrap

```javascript
import { Application, Assets } from 'pixi.js';

async function startGame() {
  const app = new Application();
  await app.init({
    width: 960,
    height: 540,
    backgroundColor: 0x1a1a2e,
    antialias: true,
  });
  document.getElementById('game-container').appendChild(app.canvas);

  // ---- Asset manifest with bundles ----
  await Assets.init({
    basePath: '/assets/',
    manifest: {
      bundles: [
        {
          name: 'preload',
          assets: [
            { alias: 'loading-bar', src: 'ui/loading-bar.png' },
          ],
        },
        {
          name: 'game',
          assets: [
            { alias: 'hero-sheet', src: 'sprites/hero.json' },
            { alias: 'tileset', src: 'maps/tileset.json' },
            { alias: 'bgm', src: 'audio/bgm.mp3' },
          ],
        },
      ],
    },
  });

  await Assets.loadBundle('preload');
  Assets.backgroundLoadBundle('game');

  // ---- Responsive canvas ----
  function resize() {
    const parent = app.canvas.parentElement;
    if (!parent) return;
    app.renderer.resize(parent.clientWidth, parent.clientHeight);
  }
  window.addEventListener('resize', resize);
  resize();

  // ---- Start game loop ----
  const game = new Game(app);
  app.ticker.add((ticker) => game.update(ticker.deltaTime));
}

startGame();
```

---

## Core Game Architecture

### Scene Management

Scenes are Containers swapped on/off the stage. A minimal SceneManager:

```javascript
import { Container } from 'pixi.js';

class SceneManager {
  constructor(app) {
    this.app = app;
    this.currentScene = null;
  }

  async switchTo(SceneClass, data) {
    if (this.currentScene) {
      this.currentScene.onExit?.();
      this.app.stage.removeChild(this.currentScene);
      this.currentScene.destroy({ children: true });
    }
    this.currentScene = new SceneClass(this.app, this);
    this.app.stage.addChild(this.currentScene);
    await this.currentScene.onEnter?.(data);
  }
}

// Base scene pattern
class GameScene extends Container {
  constructor(app, scenes) {
    super();
    this.app = app;
    this.scenes = scenes;
  }
  async onEnter(data) { /* load assets, build UI */ }
  update(dt) { /* per-frame logic */ }
  onExit() { /* cleanup */ }
}
```

See [references/game-architecture.md](references/game-architecture.md) for state machines, ECS-lite, and save/load patterns.

### Input System

Track keyboard state for continuous movement (not just events):

```javascript
class Keyboard {
  constructor() {
    this.keys = new Set();
    window.addEventListener('keydown', (e) => this.keys.add(e.code));
    window.addEventListener('keyup', (e) => this.keys.delete(e.code));
  }
  isDown(code) { return this.keys.has(code); }
  destroy() {
    window.removeEventListener('keydown', this._onDown);
    window.removeEventListener('keyup', this._onUp);
  }
}

// Usage in update loop
if (keyboard.isDown('ArrowRight')) player.x += speed * dt;
```

For pointer/touch input, use PixiJS events on the stage:

```javascript
app.stage.eventMode = 'static';
app.stage.hitArea = app.screen;
app.stage.on('pointermove', (e) => {
  crosshair.position.copyFrom(e.global);
});
```

### Game Loop: Fixed Timestep

Use fixed timestep for deterministic physics, variable for rendering:

```javascript
class Game {
  constructor(app) {
    this.app = app;
    this.fixedStep = 1 / 60;   // 60 Hz physics
    this.accumulator = 0;
  }

  update(dt) {
    const deltaSec = dt / 60;  // ticker.deltaTime is frame-based, convert to seconds
    this.accumulator += deltaSec;

    while (this.accumulator >= this.fixedStep) {
      this.fixedUpdate(this.fixedStep);
      this.accumulator -= this.fixedStep;
    }

    this.render(this.accumulator / this.fixedStep); // interpolation alpha
  }

  fixedUpdate(step) { /* physics, collision */ }
  render(alpha) { /* visual interpolation, particles, animations */ }
}
```

---

## Game Objects

### Sprites and Animated Sprites

```javascript
import { Sprite, AnimatedSprite, Assets } from 'pixi.js';

// Static sprite
const texture = Assets.get('hero-sheet');
const hero = new Sprite(texture);
hero.anchor.set(0.5);

// Animated sprite from spritesheet
const sheet = Assets.get('hero-sheet');
const walkFrames = Object.keys(sheet.textures)
  .filter((k) => k.startsWith('walk_'))
  .map((k) => sheet.textures[k]);

const animHero = new AnimatedSprite(walkFrames);
animHero.anchor.set(0.5);
animHero.animationSpeed = 0.15;
animHero.play();
```

### BitmapText for HUD

Use BitmapText for scores, timers, and any text that updates every frame:

```javascript
import { BitmapText, BitmapFont } from 'pixi.js';

BitmapFont.install({ name: 'GameFont', style: { fontSize: 32, fill: 0xffffff } });

const scoreText = new BitmapText({
  text: 'Score: 0',
  style: { fontFamily: 'GameFont', fontSize: 32 },
});
scoreText.position.set(16, 16);

// Update cheaply every frame
scoreText.text = `Score: ${score}`;
```

### Object Pooling

Reuse objects instead of create/destroy (bullets, particles, enemies):

```javascript
class Pool {
  constructor(factory, reset) {
    this.factory = factory;
    this.reset = reset;
    this.available = [];
  }

  get() {
    const obj = this.available.length > 0
      ? this.available.pop()
      : this.factory();
    this.reset(obj);
    return obj;
  }

  release(obj) {
    obj.visible = false;
    this.available.push(obj);
  }
}

// Example: bullet pool
const bulletPool = new Pool(
  () => { const s = new Sprite(bulletTex); s.anchor.set(0.5); return s; },
  (s) => { s.visible = true; s.alpha = 1; },
);
```

---

## Game World

### Camera (Scrolling World)

Manual camera -- move a world container opposite to the target:

```javascript
const world = new Container({ isRenderGroup: true });
app.stage.addChild(world);

function updateCamera(target, screen) {
  world.x = -target.x + screen.width / 2;
  world.y = -target.y + screen.height / 2;
}
```

For zoom, bounds clamping, and inertia, use **pixi-viewport**:

```javascript
import { Viewport } from 'pixi-viewport';

const viewport = new Viewport({
  screenWidth: app.screen.width,
  screenHeight: app.screen.height,
  worldWidth: 3000,
  worldHeight: 3000,
  events: app.renderer.events,
});
app.stage.addChild(viewport);
viewport.drag().pinch().wheel().decelerate();
viewport.follow(player, { speed: 10 });
```

### Collision Detection

**AABB (axis-aligned bounding box):**

```javascript
function aabb(a, b) {
  return (
    a.x < b.x + b.width &&
    a.x + a.width > b.x &&
    a.y < b.y + b.height &&
    a.y + a.height > b.y
  );
}
```

**Circle collision:**

```javascript
function circleHit(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  const dist = a.radius + b.radius;
  return dx * dx + dy * dy < dist * dist;
}
```

For complex physics (rigid bodies, joints, platformers), integrate **Matter.js** -- see [references/ecosystem.md](references/ecosystem.md).

### Tilemaps

Use **@pixi/tilemap** for efficient grid-based maps:

```javascript
import { CompositeTilemap } from '@pixi/tilemap';

const tilemap = new CompositeTilemap();
for (let y = 0; y < mapHeight; y++) {
  for (let x = 0; x < mapWidth; x++) {
    const tileId = mapData[y][x];
    tilemap.tile(tileTextures[tileId], x * tileSize, y * tileSize);
  }
}
world.addChild(tilemap);
```

---

## Ecosystem Libraries

| Package | Version (v8-compat) | Purpose |
|---------|---------------------|---------|
| `@pixi/sound` | ^6.x | Audio playback, sprites, filters |
| `pixi-viewport` | ^5.x | Camera: pan, zoom, follow, cull |
| `@pixi/tilemap` | ^4.x | Fast tilemap rendering |
| `@pixi/ui` | ^2.x | Buttons, sliders, scroll, list |
| `@pixi/particle-emitter` | ^5.x | Configurable particle systems |
| `matter-js` | ^0.20 | 2D physics engine |
| `@esotericsoftware/spine-pixi-v8` | ^4.2 | Spine skeletal animation |
| `pixi-filters` | ^6.x | 40+ post-processing filters |

Install only what you need. See [references/ecosystem.md](references/ecosystem.md) for integration patterns.

---

## Performance Essentials

**Draw call budget**: aim for < 100 on mobile, < 300 on desktop.

| Technique | When to use |
|-----------|------------|
| Sprite sheets / atlases | Always -- consolidate into few textures |
| Object pooling | Any object created/destroyed frequently (bullets, particles, pickups) |
| `isRenderGroup: true` | Separate game layers (world, HUD, particles) |
| `ParticleContainer` | Mass identical sprites (rain, stars, bullets) -- only accepts `Particle` objects in v8 |
| `BitmapText` over `Text` | Any text that updates per frame |
| `cacheAsTexture()` | Complex static sub-trees that rarely change |
| Reduce filter count | Each filter = extra render pass |

**Mobile-specific:**
- Disable antialiasing: `antialias: false`
- Set `backgroundAlpha: 1` (avoids compositing cost)
- Use `@0.5x` resolution textures
- Cap resolution: `resolution: Math.min(window.devicePixelRatio, 2)`
- Minimize filters and blend mode switches

See [references/performance.md](references/performance.md) for full optimization guide.

---

## v8 Gotchas Checklist

Common mistakes when writing PixiJS 8.x game code:

- **Forgot async init**: `new Application()` then `await app.init({...})` -- constructor alone does nothing
- **Used `app.view`**: renamed to `app.canvas`
- **Used `container.name`**: renamed to `container.label`
- **Used `Texture.from(url)`**: must `await Assets.load(url)` first -- no lazy loading in v8
- **Used `cacheAsBitmap = true`**: replaced by `cacheAsTexture()` method
- **Used `updateTransform()`**: replaced by `onRender()` callback
- **Added children to Sprite**: only `Container` can have children in v8
- **Ticker callback expects raw delta**: callback receives `Ticker` instance -- use `ticker.deltaTime`
- **Used `beginFill/endFill`**: Graphics uses chainable `.rect().fill()` API
- **Used positional constructor args**: most classes take config objects -- `new BlurFilter({ strength: 8 })`
- **Forgot `eventMode = 'static'`**: default is `'passive'` (no events) -- must opt in
- **ParticleContainer with Sprites**: v8 only accepts `Particle` objects, not `Sprite`
- **Used `getBounds()` as Rectangle**: returns `Bounds` object -- access `.rectangle` for the rect
- **Imported from sub-packages**: use `import { ... } from 'pixi.js'` -- single entry point
- **Used `PIXI.settings`**: removed -- use `AbstractRenderer.defaultOptions`
