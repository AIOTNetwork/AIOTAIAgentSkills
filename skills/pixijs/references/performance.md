# PixiJS 8.x Game Performance Guide

## Table of Contents

- [Draw Call Budget](#draw-call-budget)
- [Texture Atlas Strategy](#texture-atlas-strategy)
- [Object Pooling](#object-pooling)
- [Fixed Timestep](#fixed-timestep)
- [Spatial Partitioning](#spatial-partitioning)
- [Render Groups & Caching](#render-groups--caching)
- [ParticleContainer](#particlecontainer)
- [Text Performance](#text-performance)
- [Batching Rules](#batching-rules)
- [Memory Lifecycle](#memory-lifecycle)
- [Mobile Optimization](#mobile-optimization)
- [Profiling Checklist](#profiling-checklist)

---

## Draw Call Budget

| Target  | Draw Calls | Notes                         |
| ------- | ---------- | ----------------------------- |
| Mobile  | < 100      | GPU-limited, thermal throttle |
| Desktop | < 300      | Comfortable headroom          |

**Measure:** Install `@pixi/devtools` extension for scene tree and batch count.

**Reduce:** Pack sprites into shared atlases, group by blend mode, minimize filters, use `ParticleContainer` for bulk sprites.

---

## Texture Atlas Strategy

| Atlas Size | Support                              |
| ---------- | ------------------------------------ |
| 2048x2048  | Safe for all devices including old mobile |
| 4096x4096  | Modern mobile and all desktop        |

- **Tools:** TexturePacker, free-tex-packer, Shoebox.
- **Resolution tiers:** `@1x` for desktop/high-DPI, `@0.5x` for low-end mobile (auto-resolved by PixiJS).
- **Batching rule:** 16 or fewer unique textures per batch. Beyond that triggers a flush.

---

## Object Pooling

**When:** Any object created/destroyed more than ~10 times per second.
**Targets:** Bullets, particles, enemies, damage numbers, pickups, hit effects.

```javascript
class Pool {
  #available = [];
  #factory;
  constructor(factory, preWarm = 0) {
    this.#factory = factory;
    for (let i = 0; i < preWarm; i++) this.#available.push(this.#factory());
  }
  get() {
    const obj = this.#available.pop() ?? this.#factory();
    obj.visible = true;
    return obj;
  }
  release(obj) {
    obj.visible = false;
    this.#available.push(obj);
  }
}

const bulletPool = new Pool(() => new Sprite(bulletTexture), 200);
```

Set `visible = false` on release, never `destroy()`. Pre-warm to expected peak count.

---

## Fixed Timestep

**Why:** Deterministic physics, consistent behavior across 30/60/144Hz, replay support.
**Values:** 60Hz (16.67ms) for desktop, 30Hz for mobile if CPU-bound.

```javascript
const STEP = 1000 / 60;
let accumulator = 0;

app.ticker.add((ticker) => {
  accumulator = Math.min(accumulator + ticker.deltaMS, 200); // cap to prevent spiral
  while (accumulator >= STEP) {
    updatePhysics(STEP);
    accumulator -= STEP;
  }
  interpolateRenderPositions(accumulator / STEP);
});
```

Interpolation: render at `prev + (current - prev) * alpha` for smooth visuals between steps.

---

## Spatial Partitioning

**When:** More than ~100 entities needing collision checks per frame.

```javascript
class SpatialGrid {
  #size; #cells = new Map();
  constructor(cellSize = 128) { this.#size = cellSize; }
  #key(x, y) { return `${(x / this.#size) | 0},${(y / this.#size) | 0}`; }
  insert(e) {
    const k = this.#key(e.x, e.y);
    if (!this.#cells.has(k)) this.#cells.set(k, []);
    this.#cells.get(k).push(e);
  }
  query(x, y, radius = 1) {
    const r = [], cr = Math.ceil(radius / this.#size);
    const cx = (x / this.#size) | 0, cy = (y / this.#size) | 0;
    for (let dx = -cr; dx <= cr; dx++)
      for (let dy = -cr; dy <= cr; dy++) {
        const c = this.#cells.get(`${cx + dx},${cy + dy}`);
        if (c) r.push(...c);
      }
    return r;
  }
  clear() { this.#cells.clear(); }
}
```

Rebuild every physics step. Use quadtree instead for non-uniform entity distribution.

---

## Render Groups & Caching

```javascript
const gameWorld = new Container({ isRenderGroup: true });
const particles = new Container({ isRenderGroup: true });
const hud = new Container({ isRenderGroup: true });
app.stage.addChild(gameWorld, particles, hud);
```

**Cache static content** to avoid re-rendering unchanged layers:

```javascript
background.cacheAsTexture();          // render once
background.updateCacheTexture();      // call when content changes
```

Do not over-apply render groups or cache dynamic content. Profile before and after.

---

## ParticleContainer

**When:** More than ~1000 similar sprites (bullets, raindrops, stars, sparks).

```javascript
const particles = new ParticleContainer({
  dynamicProperties: { position: true, scale: true, rotation: true, tint: true, alpha: true },
});
for (let i = 0; i < 5000; i++) {
  const p = new Particle({ texture: sparkTexture });
  p.x = Math.random() * 800;
  p.y = Math.random() * 600;
  particles.addChild(p);
}
```

v8 uses `Particle` objects, NOT `Sprite`. No children, no filters, no interaction — render only.

---

## Text Performance

| Type         | Use Case                        | Update Cost    |
| ------------ | ------------------------------- | -------------- |
| `BitmapText` | Scores, timers, FPS, damage numbers | Very low       |
| `Text`       | Static labels, menus, dialog    | High on change |

- Use `BitmapText` for anything updating every frame.
- `Text` re-rasterizes canvas + re-uploads to GPU on every change — never update per frame.
- Pool text objects for damage numbers. Lower `resolution` on large `Text` blocks.

---

## Batching Rules

Same texture + same blend mode = one batch.

**Batch breakers:** Blend mode change, different base texture, filter/mask, render group boundary.

**Optimal render order:**
1. Backgrounds (static, cached)
2. Game objects grouped by atlas
3. Particles (ParticleContainer)
4. HUD / UI (separate render group)

Do not interleave sprites from different atlases — sort children by texture when possible.

---

## Memory Lifecycle

| Phase            | Action                                            |
| ---------------- | ------------------------------------------------- |
| Loading screen   | `Assets.load()` game bundle, show progress        |
| Gameplay         | Assets stay loaded, pools pre-warmed              |
| Scene transition | Unload previous scene's unique assets             |
| Post-cutscene    | `Assets.unload()` for large one-time assets       |

```javascript
sprite.destroy({ children: true, texture: false }); // keep shared textures
await Assets.unload('cutscene-bg');                  // free one-time assets
```

Avoid GC spikes: pool objects, reuse `Point`/`Rectangle` instances, never allocate inside the game loop.

---

## Mobile Optimization

```javascript
await app.init({
  backgroundAlpha: 1,
  antialias: false,
  resolution: Math.min(window.devicePixelRatio, 2),
});
app.ticker.maxFPS = 30; // if 60fps not achievable
```

- Halve particle counts vs desktop.
- Use `@0.5x` atlas resolution tier.
- Avoid filters or limit to one simple filter.
- Touch input: minimum 44px hit areas — use `hitArea` for small targets.

---

## Profiling Checklist

| Check              | Tool                         | Red Flag                              |
| ------------------ | ---------------------------- | ------------------------------------- |
| Long frames        | Chrome DevTools Performance  | Frames > 16ms                         |
| Scene/texture info | `@pixi/devtools` extension   | > 16 textures per batch               |
| GPU render time    | `renderer.render()` timing   | > 16ms = GPU bound                    |
| CPU update time    | Ticker callback timing       | > 8ms = CPU bound                     |
| GC pauses          | Memory timeline              | Frequent spikes = needs pooling       |
| Draw call count    | `@pixi/devtools` extension   | Above budget (100 mobile, 300 desktop)|

**Priority when optimizing:** Reduce draw calls > pool allocations > optimize update logic > reduce visual fidelity.
