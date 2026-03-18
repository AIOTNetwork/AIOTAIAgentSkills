# PixiJS 8.x Game Architecture Patterns

## Table of Contents

- [Input System](#input-system)
  - [Keyboard State Tracker](#keyboard-state-tracker)
  - [Pointer and Touch](#pointer-and-touch)
  - [Gamepad API](#gamepad-api)
- [Scene Management](#scene-management)
  - [Scene Base Class](#scene-base-class)
  - [SceneManager](#scenemanager)
- [Camera System](#camera-system)
  - [Manual Follow Camera](#manual-follow-camera)
  - [pixi-viewport Integration](#pixi-viewport-integration)
- [Collision Detection](#collision-detection)
  - [AABB (Axis-Aligned Bounding Box)](#aabb-axis-aligned-bounding-box)
  - [Circle Collision](#circle-collision)
  - [Spatial Hash Grid](#spatial-hash-grid)
- [Object Pooling](#object-pooling)
  - [Generic Pool Class](#generic-pool-class)
  - [Common Pool Targets](#common-pool-targets)
- [Game State Machine](#game-state-machine)
- [Entity Pattern](#entity-pattern)

---

## Input System

### Keyboard State Tracker

Tracks held, just-pressed, and just-released keys. Call `update()` once per frame after processing input.

```javascript
class Keyboard {
  constructor() {
    this._held = new Set();
    this._pressed = new Set();
    this._released = new Set();

    window.addEventListener('keydown', (e) => {
      if (!this._held.has(e.code)) this._pressed.add(e.code);
      this._held.add(e.code);
    });
    window.addEventListener('keyup', (e) => {
      this._held.delete(e.code);
      this._released.add(e.code);
    });
  }

  isDown(code) { return this._held.has(code); }
  justPressed(code) { return this._pressed.has(code); }
  justReleased(code) { return this._released.has(code); }

  /** Call at end of each frame to clear single-frame states. */
  update() {
    this._pressed.clear();
    this._released.clear();
  }
}
```

**Usage in game loop:**

```javascript
const keyboard = new Keyboard();

app.ticker.add((ticker) => {
  const dt = ticker.deltaTime;
  if (keyboard.isDown('ArrowRight')) player.x += speed * dt;
  if (keyboard.justPressed('Space')) player.jump();
  keyboard.update();
});
```

### Pointer and Touch

Reminder: PixiJS 8.x defaults to `eventMode = 'passive'`. Set `'static'` on interactive objects.

**Drag pattern:**

```javascript
function makeDraggable(target) {
  target.eventMode = 'static';
  target.cursor = 'grab';
  let dragging = false;
  let offset = { x: 0, y: 0 };

  target.on('pointerdown', (e) => {
    dragging = true;
    const pos = e.getLocalPosition(target.parent);
    offset.x = target.x - pos.x;
    offset.y = target.y - pos.y;
    target.cursor = 'grabbing';
    target.alpha = 0.8;
  });
  target.on('globalpointermove', (e) => {
    if (!dragging) return;
    const pos = e.getLocalPosition(target.parent);
    target.x = pos.x + offset.x;
    target.y = pos.y + offset.y;
  });
  target.on('pointerup', () => {
    dragging = false;
    target.cursor = 'grab';
    target.alpha = 1;
  });
  target.on('pointerupoutside', () => {
    dragging = false;
    target.cursor = 'grab';
    target.alpha = 1;
  });
}
```

**Touch joystick pattern (mobile):**

```javascript
class TouchJoystick {
  constructor(container, radius = 60) {
    this.radius = radius;
    this.dx = 0;
    this.dy = 0;
    this.active = false;

    this.base = new Graphics().circle(0, 0, radius).fill({ color: 0xffffff, alpha: 0.2 });
    this.knob = new Graphics().circle(0, 0, radius * 0.4).fill({ color: 0xffffff, alpha: 0.5 });
    this.base.addChild(this.knob);
    this.base.visible = false;
    container.addChild(this.base);

    container.eventMode = 'static';
    container.on('pointerdown', (e) => {
      const pos = e.getLocalPosition(container);
      this.base.position.set(pos.x, pos.y);
      this.base.visible = true;
      this.active = true;
    });
    container.on('globalpointermove', (e) => {
      if (!this.active) return;
      const pos = e.getLocalPosition(container);
      let ox = pos.x - this.base.x;
      let oy = pos.y - this.base.y;
      const dist = Math.sqrt(ox * ox + oy * oy);
      if (dist > radius) { ox *= radius / dist; oy *= radius / dist; }
      this.knob.position.set(ox, oy);
      this.dx = ox / radius;
      this.dy = oy / radius;
    });
    container.on('pointerup', () => this._reset());
    container.on('pointerupoutside', () => this._reset());
  }

  _reset() {
    this.active = false;
    this.dx = 0;
    this.dy = 0;
    this.knob.position.set(0, 0);
    this.base.visible = false;
  }
}
```

### Gamepad API

Poll gamepads each frame — the Gamepad API is snapshot-based, not event-driven.

```javascript
class GamepadInput {
  constructor(deadzone = 0.15) {
    this.deadzone = deadzone;
    this.axes = [0, 0, 0, 0];
    this.buttons = [];
    this._prevButtons = [];
  }

  update() {
    const gp = navigator.getGamepads()[0];
    if (!gp) return;
    this._prevButtons = [...this.buttons];
    this.axes = gp.axes.map((v) => Math.abs(v) < this.deadzone ? 0 : v);
    this.buttons = gp.buttons.map((b) => b.pressed);
  }

  /** Left stick X/Y. */
  get leftStick() { return { x: this.axes[0], y: this.axes[1] }; }
  /** Right stick X/Y. */
  get rightStick() { return { x: this.axes[2], y: this.axes[3] }; }
  /** True only on the frame the button was first pressed. */
  justPressed(index) { return this.buttons[index] && !this._prevButtons[index]; }
  isDown(index) { return !!this.buttons[index]; }
}

// Standard mapping: 0=A, 1=B, 2=X, 3=Y, 12=Up, 13=Down, 14=Left, 15=Right
```

---

## Scene Management

### Scene Base Class

Each scene extends `Container` and exposes lifecycle hooks the manager calls.

```javascript
import { Container, Assets } from 'pixi.js';

class Scene extends Container {
  /** Override to return an array of asset URLs this scene needs. */
  get assets() { return []; }

  /** Called after assets are loaded and the scene is added to stage. */
  onEnter() {}

  /** Called before the scene is removed from stage. */
  onExit() {}

  /** Called every frame by the scene manager. */
  update(dt) {}

  /** Called when the renderer resizes. */
  resize(w, h) {}
}
```

### SceneManager

Manages a scene stack with optional fade transitions.

```javascript
import { Assets, Graphics } from 'pixi.js';

class SceneManager {
  constructor(app) {
    this.app = app;
    this.stack = [];
    this.current = null;
    this._overlay = new Graphics();
    this._overlay.rect(0, 0, 1, 1).fill(0x000000);
    this._overlay.alpha = 0;
    this._transitioning = false;

    app.ticker.add((ticker) => {
      if (this.current && !this._transitioning) {
        this.current.update(ticker.deltaTime);
      }
    });
  }

  async goto(SceneClass, transition = true) {
    if (this._transitioning) return;
    const next = new SceneClass();

    if (transition) await this._fadeOut();

    if (this.current) {
      this.current.onExit();
      this.app.stage.removeChild(this.current);
      this.current.destroy({ children: true });
    }
    this.stack = [next];

    if (next.assets.length) await Assets.load(next.assets);

    this.current = next;
    this.app.stage.addChild(this.current);
    this.current.onEnter();
    this._addOverlay();

    if (transition) await this._fadeIn();
  }

  async push(SceneClass) {
    if (this._transitioning) return;
    const next = new SceneClass();
    if (next.assets.length) await Assets.load(next.assets);
    if (this.current) this.current.onExit();
    this.stack.push(next);
    this.current = next;
    this.app.stage.addChild(this.current);
    this.current.onEnter();
  }

  async pop() {
    if (this._transitioning || this.stack.length <= 1) return;
    this.current.onExit();
    this.app.stage.removeChild(this.current);
    this.current.destroy({ children: true });
    this.stack.pop();
    this.current = this.stack[this.stack.length - 1];
    this.app.stage.addChild(this.current);
    this.current.onEnter();
  }

  _addOverlay() {
    const { width, height } = this.app.renderer;
    this._overlay.scale.set(width, height);
    this.app.stage.addChild(this._overlay);
  }

  _fadeOut(duration = 300) {
    return this._animate(0, 1, duration);
  }

  _fadeIn(duration = 300) {
    return this._animate(1, 0, duration);
  }

  _animate(from, to, duration) {
    this._transitioning = true;
    this._addOverlay();
    this._overlay.alpha = from;
    return new Promise((resolve) => {
      const start = performance.now();
      const tick = () => {
        const t = Math.min((performance.now() - start) / duration, 1);
        this._overlay.alpha = from + (to - from) * t;
        if (t < 1) {
          requestAnimationFrame(tick);
        } else {
          this._transitioning = false;
          if (to === 0) this.app.stage.removeChild(this._overlay);
          resolve();
        }
      };
      requestAnimationFrame(tick);
    });
  }
}
```

**Usage:**

```javascript
const scenes = new SceneManager(app);
await scenes.goto(MenuScene);
// Later: await scenes.goto(GameScene);
// Pause overlay: await scenes.push(PauseScene);
// Resume: await scenes.pop();
```

---

## Camera System

### Manual Follow Camera

Move a world container inversely to the target. Works without any plugins.

```javascript
class Camera {
  constructor(worldContainer, viewWidth, viewHeight) {
    this.world = worldContainer;
    this.viewW = viewWidth;
    this.viewH = viewHeight;
    this.lerp = 0.1;
    this.deadzone = { x: 50, y: 30 };
    this.bounds = null; // { minX, minY, maxX, maxY }
  }

  follow(target, dt) {
    const cx = this.viewW / 2;
    const cy = this.viewH / 2;
    let goalX = cx - target.x;
    let goalY = cy - target.y;

    // Deadzone — only move camera when target exceeds deadzone
    const dx = target.x + this.world.x - cx;
    const dy = target.y + this.world.y - cy;
    if (Math.abs(dx) < this.deadzone.x) goalX = this.world.x;
    if (Math.abs(dy) < this.deadzone.y) goalY = this.world.y;

    // Smooth lerp
    this.world.x += (goalX - this.world.x) * this.lerp * dt;
    this.world.y += (goalY - this.world.y) * this.lerp * dt;

    // Clamp to world bounds
    if (this.bounds) {
      this.world.x = Math.min(-this.bounds.minX, Math.max(-this.bounds.maxX + this.viewW, this.world.x));
      this.world.y = Math.min(-this.bounds.minY, Math.max(-this.bounds.maxY + this.viewH, this.world.y));
    }
  }

  resize(w, h) {
    this.viewW = w;
    this.viewH = h;
  }
}
```

**When to use:** Any scrolling game — platformers, RPGs, top-down exploration.

### pixi-viewport Integration

`pixi-viewport` adds zoom, pinch, and inertia scrolling on top of PixiJS 8.x.

```bash
npm install pixi-viewport
```

```javascript
import { Viewport } from 'pixi-viewport';

const viewport = new Viewport({
  screenWidth: app.renderer.width,
  screenHeight: app.renderer.height,
  worldWidth: 3000,
  worldHeight: 3000,
  events: app.renderer.events,
});
app.stage.addChild(viewport);

viewport
  .drag()
  .pinch()
  .wheel()
  .decelerate();

viewport.clamp({ left: 0, right: 3000, top: 0, bottom: 3000 });

// Follow a target with smooth tracking
viewport.follow(player, { speed: 10, radius: 100 });
```

**When to use:** Maps, strategy games, sandbox worlds, or any game needing zoom/pan.

---

## Collision Detection

### AABB (Axis-Aligned Bounding Box)

Uses PixiJS built-in `getBounds()`. Fast and simple for rectangular objects.

```javascript
function aabbCollision(a, b) {
  const ab = a.getBounds();
  const bb = b.getBounds();
  return (
    ab.x < bb.x + bb.width &&
    ab.x + ab.width > bb.x &&
    ab.y < bb.y + bb.height &&
    ab.y + ab.height > bb.y
  );
}
```

**When to use:** UI hit tests, platformer tiles, simple rectangular entities.

### Circle Collision

Distance-based check. Better for round objects or approximate checks.

```javascript
function circleCollision(a, aRadius, b, bRadius) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  const distSq = dx * dx + dy * dy;
  const radii = aRadius + bRadius;
  return distSq <= radii * radii;
}
```

**When to use:** Top-down shooters, balls, particles, proximity triggers.

### Spatial Hash Grid

Broad-phase optimization. Divides the world into grid cells and only checks entities in the same or adjacent cells.

```javascript
class SpatialHash {
  constructor(cellSize = 128) {
    this.cellSize = cellSize;
    this.cells = new Map();
  }

  _key(cx, cy) { return `${cx},${cy}`; }

  clear() { this.cells.clear(); }

  insert(entity) {
    const b = entity.getBounds();
    const minCX = Math.floor(b.x / this.cellSize);
    const minCY = Math.floor(b.y / this.cellSize);
    const maxCX = Math.floor((b.x + b.width) / this.cellSize);
    const maxCY = Math.floor((b.y + b.height) / this.cellSize);
    for (let cx = minCX; cx <= maxCX; cx++) {
      for (let cy = minCY; cy <= maxCY; cy++) {
        const key = this._key(cx, cy);
        if (!this.cells.has(key)) this.cells.set(key, []);
        this.cells.get(key).push(entity);
      }
    }
  }

  /** Returns candidate entities that share a cell with the given entity. */
  query(entity) {
    const b = entity.getBounds();
    const minCX = Math.floor(b.x / this.cellSize);
    const minCY = Math.floor(b.y / this.cellSize);
    const maxCX = Math.floor((b.x + b.width) / this.cellSize);
    const maxCY = Math.floor((b.y + b.height) / this.cellSize);
    const found = new Set();
    for (let cx = minCX; cx <= maxCX; cx++) {
      for (let cy = minCY; cy <= maxCY; cy++) {
        const cell = this.cells.get(this._key(cx, cy));
        if (cell) cell.forEach((e) => { if (e !== entity) found.add(e); });
      }
    }
    return found;
  }
}
```

**Usage each frame:**

```javascript
const grid = new SpatialHash(128);
// In update loop:
grid.clear();
entities.forEach((e) => grid.insert(e));
entities.forEach((e) => {
  for (const other of grid.query(e)) {
    if (aabbCollision(e, other)) handleCollision(e, other);
  }
});
```

**When to use:** More than ~100 collidable entities. Reduces O(n^2) to near-linear.

---

## Object Pooling

### Generic Pool Class

Avoids garbage collection spikes from constant create/destroy cycles.

```javascript
class ObjectPool {
  constructor(createFn, resetFn, initialSize = 0) {
    this._create = createFn;
    this._reset = resetFn;
    this._pool = [];
    // Pre-warm
    for (let i = 0; i < initialSize; i++) {
      this._pool.push(this._create());
    }
  }

  get() {
    const obj = this._pool.length > 0 ? this._pool.pop() : this._create();
    this._reset(obj);
    return obj;
  }

  release(obj) {
    this._pool.push(obj);
  }

  get size() { return this._pool.length; }
}
```

**Usage:**

```javascript
const bulletPool = new ObjectPool(
  () => {
    const s = new Sprite(bulletTexture);
    s.anchor.set(0.5);
    return s;
  },
  (s) => {
    s.x = 0;
    s.y = 0;
    s.rotation = 0;
    s.visible = true;
    s.alpha = 1;
  },
  50, // pre-warm with 50 bullets
);

// Spawn
const bullet = bulletPool.get();
gameContainer.addChild(bullet);

// Recycle
gameContainer.removeChild(bullet);
bulletPool.release(bullet);
```

### Common Pool Targets

| Object Type | Why Pool It |
|---|---|
| Bullets / projectiles | Created and destroyed many times per second |
| Particle effects | Short-lived, high volume |
| Enemy spawns | Waves of identical enemies |
| Damage numbers / floating text | Frequent, short-lived text labels |

---

## Game State Machine

Simple FSM to manage top-level game flow. Each state has enter/exit/update hooks.

```javascript
class GameFSM {
  constructor() {
    this.states = {};
    this.current = null;
  }

  add(name, state) {
    // state = { enter(), exit(), update(dt) }
    this.states[name] = state;
  }

  change(name, ...args) {
    if (this.current && this.states[this.current].exit) {
      this.states[this.current].exit();
    }
    this.current = name;
    if (this.states[name].enter) {
      this.states[name].enter(...args);
    }
  }

  update(dt) {
    if (this.current && this.states[this.current].update) {
      this.states[this.current].update(dt);
    }
  }
}
```

**Usage:**

```javascript
const fsm = new GameFSM();

fsm.add('menu', {
  enter() { showMenuUI(); },
  exit() { hideMenuUI(); },
});

fsm.add('playing', {
  enter() { spawnPlayer(); },
  update(dt) { updateGameplay(dt); },
  exit() { cleanupLevel(); },
});

fsm.add('gameover', {
  enter(score) { showGameOver(score); },
  exit() { hideGameOver(); },
});

fsm.change('menu');

app.ticker.add((ticker) => {
  fsm.update(ticker.deltaTime);
});
```

---

## Entity Pattern

### Base Game Entity

Wraps a PixiJS display object with game logic lifecycle. Supports pooling via active/inactive toggling.

```javascript
class GameEntity {
  constructor(displayObject) {
    this.display = displayObject;
    this.active = true;
    this.vx = 0;
    this.vy = 0;
  }

  get x() { return this.display.x; }
  set x(v) { this.display.x = v; }
  get y() { return this.display.y; }
  set y(v) { this.display.y = v; }

  update(dt) {
    if (!this.active) return;
    this.x += this.vx * dt;
    this.y += this.vy * dt;
  }

  activate(x, y) {
    this.active = true;
    this.display.visible = true;
    this.x = x;
    this.y = y;
  }

  deactivate() {
    this.active = false;
    this.display.visible = false;
    this.vx = 0;
    this.vy = 0;
  }

  destroy() {
    this.display.destroy({ children: true });
  }
}
```

**Extended example — a bullet entity:**

```javascript
class Bullet extends GameEntity {
  constructor(texture) {
    super(new Sprite(texture));
    this.display.anchor.set(0.5);
    this.speed = 8;
    this.damage = 1;
  }

  fire(x, y, angle) {
    this.activate(x, y);
    this.display.rotation = angle;
    this.vx = Math.cos(angle) * this.speed;
    this.vy = Math.sin(angle) * this.speed;
  }

  update(dt) {
    super.update(dt);
    // Deactivate when off screen
    if (this.x < -50 || this.x > screenW + 50 || this.y < -50 || this.y > screenH + 50) {
      this.deactivate();
    }
  }
}
```
