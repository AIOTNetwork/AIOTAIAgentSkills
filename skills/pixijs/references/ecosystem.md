# PixiJS 8.x Game Ecosystem

## Table of Contents

- [Library Compatibility Table](#library-compatibility-table)
- [@pixi/sound](#pixisound)
- [pixi-viewport](#pixi-viewport)
- [@pixi/tilemap](#pixitilemap)
- [@pixi/ui](#pixiui)
- [@pixi/particle-emitter](#pixiparticle-emitter)
- [Matter.js Integration](#matterjs-integration)
- [@esotericsoftware/spine-pixi-v8](#esotericsoftwarespine-pixi-v8)
- [pixi-filters](#pixi-filters)

---

## Library Compatibility Table

| Library | Package | v8 Version | Purpose |
|---------|---------|------------|---------|
| Sound | `@pixi/sound` | `^6.0.0` | Audio playback, sprites, spatial |
| Viewport | `pixi-viewport` | `^5.2.0` | Camera, pan, zoom, follow |
| Tilemap | `@pixi/tilemap` | `^4.1.0` | Tile-based map rendering |
| UI | `@pixi/ui` | `^2.0.0` | Buttons, sliders, lists, progress |
| Particles | `@pixi/particle-emitter` | `^5.0.0` | Particle effects and emitters |
| Physics | `matter-js` | `^0.20.0` | 2D rigid-body physics |
| Spine | `@esotericsoftware/spine-pixi-v8` | `^4.2.0` | Skeletal animation |
| Filters | `pixi-filters` | `^6.1.0` | Visual effects (glow, shockwave, CRT) |

---

## @pixi/sound

```bash
npm install @pixi/sound@^6.0.0
```

```javascript
import { sound } from '@pixi/sound';
import { Assets } from 'pixi.js';

Assets.add({ alias: 'bgm', src: 'audio/background.mp3' });
await Assets.load('bgm');

// Playback
sound.play('bgm', { loop: true, volume: 0.5 });
sound.stop('bgm');
sound.pause('bgm');
sound.resume('bgm');
sound.volumeAll = 0.3;

// Sound sprites -- multiple sounds in one file
const sfx = sound.add('sfx-sheet', {
  url: 'audio/sfx-sheet.mp3',
  sprites: {
    jump:   { start: 0, end: 0.4 },
    coin:   { start: 0.5, end: 0.9 },
  },
});
sfx.play('jump');

// Spatial panning (-1 left, 0 center, 1 right)
const instance = sound.play('engine', { loop: true });
app.ticker.add(() => {
  const pan = (sprite.x - app.screen.width / 2) / (app.screen.width / 2);
  instance.set('pan', Math.max(-1, Math.min(1, pan)));
});
```

---

## pixi-viewport

```bash
npm install pixi-viewport@^5.2.0
```

```javascript
import { Viewport } from 'pixi-viewport';

const viewport = new Viewport({
  screenWidth: app.screen.width,
  screenHeight: app.screen.height,
  worldWidth: 3000,
  worldHeight: 3000,
  events: app.renderer.events, // required for v8
});
app.stage.addChild(viewport);

// Interaction plugins (chainable)
viewport.drag().pinch().wheel({ smooth: 5 }).decelerate({ friction: 0.95 });

// Follow target
viewport.follow(playerSprite, { speed: 10, radius: 100 });

// Clamp to world bounds
viewport.clamp({ left: 0, right: 3000, top: 0, bottom: 3000 });
viewport.clampZoom({ minScale: 0.5, maxScale: 3 });

// Resize handling
window.addEventListener('resize', () => viewport.resize(window.innerWidth, window.innerHeight));
```

---

## @pixi/tilemap

```bash
npm install @pixi/tilemap@^4.1.0
```

```javascript
import { CompositeTilemap, settings } from '@pixi/tilemap';

settings.use32bitIndex = true; // enable for maps with >16K tiles

const tilemap = new CompositeTilemap();
app.stage.addChild(tilemap);

// Place tiles from a spritesheet
const tilesheet = await Assets.load('tilesheet.png');
for (let row = 0; row < mapHeight; row++) {
  for (let col = 0; col < mapWidth; col++) {
    const tileId = mapData[row][col];
    if (tileId >= 0) tilemap.tile(textures[tileId], col * 32, row * 32);
  }
}

// Tiled editor JSON loading pattern
async function loadTiledMap(jsonPath) {
  const map = await Assets.load(jsonPath);
  const tileset = await Assets.load(map.tilesets[0].image);
  const tw = map.tilewidth, th = map.tileheight, cols = map.tilesets[0].columns;
  const tm = new CompositeTilemap();
  for (const layer of map.layers) {
    if (layer.type !== 'tilelayer') continue;
    for (let i = 0; i < layer.data.length; i++) {
      const gid = layer.data[i];
      if (gid === 0) continue;
      const id = gid - 1;
      const frame = new Rectangle((id % cols) * tw, Math.floor(id / cols) * th, tw, th);
      tm.tile(new Texture({ source: tileset.source, frame }),
              (i % layer.width) * tw, Math.floor(i / layer.width) * th);
    }
  }
  return tm;
}
```

---

## @pixi/ui

```bash
npm install @pixi/ui@^2.0.0
```

```javascript
import { Button, ProgressBar, List, Slider } from '@pixi/ui';

// Button with hover state
const button = new Button(new Graphics().roundRect(0, 0, 200, 60, 12).fill(0x3366ff));
button.onPress.connect(() => console.log('clicked'));
button.onHover.connect(() => (button.view.tint = 0x5588ff));
button.onOut.connect(() => (button.view.tint = 0xffffff));

// ProgressBar (health/loading)
const hpBar = new ProgressBar({
  bg: new Graphics().roundRect(0, 0, 200, 20, 6).fill(0x333333),
  fill: new Graphics().roundRect(0, 0, 200, 20, 6).fill(0x22cc44),
  progress: 100,
});
hpBar.progress = player.hp; // update

// List (menus/inventories)
const menu = new List({ type: 'vertical', elementsMargin: 8 });
menu.addChild(menuItem1, menuItem2, menuItem3);

// Slider (settings)
const slider = new Slider({
  bg: new Graphics().roundRect(0, 0, 200, 10, 5).fill(0x444444),
  fill: new Graphics().roundRect(0, 0, 200, 10, 5).fill(0x2288ff),
  slider: new Graphics().circle(0, 0, 14).fill(0xffffff),
  min: 0, max: 100, value: 50,
});
slider.onUpdate.connect((value) => { sound.volumeAll = value / 100; });
```

---

## @pixi/particle-emitter

```bash
npm install @pixi/particle-emitter@^5.0.0
```

```javascript
import { Emitter } from '@pixi/particle-emitter';

const container = new Container();
app.stage.addChild(container);

const emitter = new Emitter(container, {
  lifetime: { min: 0.3, max: 0.8 },
  frequency: 0.01,
  maxParticles: 200,
  pos: { x: 0, y: 0 },
  behaviors: [
    { type: 'alpha', config: { alpha: { list: [{ time: 0, value: 1 }, { time: 1, value: 0 }] } } },
    { type: 'scale', config: { scale: { list: [{ time: 0, value: 0.5 }, { time: 1, value: 0.1 }] } } },
    { type: 'speed', config: { speed: { list: [{ time: 0, value: 200 }, { time: 1, value: 50 }] } } },
    { type: 'spawnShape', config: { type: 'torus', data: { x: 0, y: 0, radius: 10 } } },
    { type: 'textureSingle', config: { texture: await Assets.load('particle.png') } },
  ],
});
emitter.emit = true;

// Update in ticker (convert to seconds)
app.ticker.add((ticker) => {
  emitter.update(ticker.deltaTime * 0.001);
  emitter.updateOwnerPos(player.x, player.y);
});

// Explosion burst preset: set emitterLifetime: 0.1, maxParticles: 50, speed: 400
// Cleanup
emitter.emit = false;
emitter.destroy();
container.destroy({ children: true });
```

---

## Matter.js Integration

```bash
npm install matter-js@^0.20.0
```

```javascript
import Matter from 'matter-js';

const engine = Matter.Engine.create({ enableSleeping: true });
const world = engine.world;
const PHYSICS_STEP = 1000 / 60;

// Create paired physics body + sprite
function createPhysicsSprite(texture, x, y, options = {}) {
  const sprite = Sprite.from(texture);
  sprite.anchor.set(0.5);
  const body = Matter.Bodies.rectangle(x, y, sprite.width, sprite.height, options);
  Matter.Composite.add(world, body);
  return { sprite, body };
}

// Static bodies for platforms/walls
const ground = Matter.Bodies.rectangle(400, 580, 800, 40, { isStatic: true });
Matter.Composite.add(world, [ground]);

// Sync loop: Matter position -> PixiJS sprite position each frame
app.ticker.add(() => {
  Matter.Engine.update(engine, PHYSICS_STEP);
  for (const e of entities) {
    e.sprite.x = e.body.position.x;
    e.sprite.y = e.body.position.y;
    e.sprite.rotation = e.body.angle;
  }
});

// Collision events
Matter.Events.on(engine, 'collisionStart', (event) => {
  for (const pair of event.pairs) {
    if (pair.bodyA.label === 'player' && pair.bodyB.label === 'coin') collectCoin(pair.bodyB);
  }
});

// Performance: enableSleeping for idle bodies, prefer rectangles/circles over fromVertices,
// use isSensor: true for trigger zones, bound world with static walls.
```

---

## @esotericsoftware/spine-pixi-v8

```bash
npm install @esotericsoftware/spine-pixi-v8@^4.2.0
```

```javascript
import '@esotericsoftware/spine-pixi-v8'; // registers Spine loader with Assets
import { Spine } from '@esotericsoftware/spine-pixi-v8';

await Assets.load([
  { alias: 'hero-skel', src: 'spine/hero.json' },
  { alias: 'hero-atlas', src: 'spine/hero.atlas' },
]);

const hero = Spine.from({ skeleton: 'hero-skel', atlas: 'hero-atlas' });
hero.scale.set(0.5);
app.stage.addChild(hero);

// Animations (trackIndex, name, loop)
hero.state.setAnimation(0, 'idle', true);
hero.state.addAnimation(0, 'walk', true, 0); // queue after current

// Crossfade mix durations
hero.state.data.setMix('idle', 'walk', 0.2);
hero.state.data.setMix('walk', 'run', 0.15);

// Animation events
hero.state.addListener({
  event: (entry, event) => {
    if (event.data.name === 'footstep') sound.play('sfx-step');
  },
  complete: (entry) => {
    if (entry.animation.name === 'attack') hero.state.setAnimation(0, 'idle', true);
  },
});

// Attach PixiJS display objects to bone slots
const sword = Sprite.from('sword.png');
sword.anchor.set(0.5);
hero.addSlotObject('weapon-slot', sword);

// Physics constraints (Spine 4.2+) run automatically -- no extra code needed.
```

---

## pixi-filters

```bash
npm install pixi-filters@^6.1.0
```

```javascript
import { GlowFilter, ShockwaveFilter, MotionBlurFilter, CRTFilter, OutlineFilter } from 'pixi-filters';

// Glow -- pickups, UI highlights
coinSprite.filters = [new GlowFilter({ distance: 15, outerStrength: 2, color: 0xffdd33 })];

// Outline -- selected units, hover
selectedUnit.filters = [new OutlineFilter({ thickness: 3, color: 0x00ff88 })];

// Shockwave -- explosions, impacts
const shockwave = new ShockwaveFilter({ center: [0.5, 0.5], speed: 500, amplitude: 30, wavelength: 160 });
app.stage.filters = [shockwave];
shockwave.time = 0; // reset to trigger
app.ticker.add((ticker) => { shockwave.time += ticker.deltaTime * 0.01; });

// CRT -- retro style
const crt = new CRTFilter({ curvature: 3, lineWidth: 2, lineContrast: 0.2, noise: 0.1, vignetting: 0.3 });
app.stage.filters = [crt];
app.ticker.add((ticker) => { crt.time += ticker.deltaTime * 0.5; });

// Stacking: applied in order
sprite.filters = [outline, glow];

// Animated uniforms in ticker
app.ticker.add((ticker) => { glow.outerStrength = 2 + Math.sin(ticker.lastTime * 0.005); });
```
