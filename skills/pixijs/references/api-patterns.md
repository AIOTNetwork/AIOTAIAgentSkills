# PixiJS 8.x API Patterns Reference

## Table of Contents

- [Graphics Shapes](#graphics-shapes)
- [Texture System](#texture-system)
- [Text Rendering](#text-rendering)
- [Filters](#filters)
- [Custom Filters](#custom-filters)
- [Assets System](#assets-system)
- [Container API](#container-api)
- [Interaction Events](#interaction-events)
- [Spine Integration](#spine-integration)
- [AnimatedSprite](#animatedsprite)
- [ParticleContainer (v8)](#particlecontainer-v8)

---

## Graphics Shapes

All shape methods are chainable. Apply `.fill()` or `.stroke()` after shape calls.

### Basic Shapes

```javascript
g.rect(x, y, width, height)
g.circle(x, y, radius)
g.ellipse(x, y, radiusX, radiusY)
g.arc(x, y, radius, startAngle, endAngle, anticlockwise?)
g.moveTo(x, y)
g.lineTo(x, y)
g.quadraticCurveTo(cpX, cpY, toX, toY)
g.bezierCurveTo(cp1X, cp1Y, cp2X, cp2Y, toX, toY)
g.arcTo(x1, y1, x2, y2, radius)
g.poly(points)  // array of x,y pairs or Point objects
g.regularPoly(x, y, radius, sides, rotation?)
g.star(x, y, points, radius, innerRadius?, rotation?)
g.roundRect(x, y, width, height, radius)
g.chamferRect(x, y, width, height, chamfer)
g.filletRect(x, y, width, height, fillet)
g.roundPoly(x, y, radius, sides, corner, rotation?)
```

### Fill & Stroke

```javascript
// Simple
g.rect(0, 0, 100, 50).fill(0xff0000);
g.rect(0, 0, 100, 50).stroke(0x000000);

// With options
g.fill({ color: 0xff0000, alpha: 0.5 });
g.stroke({ color: 0x000000, width: 2, alignment: 0.5 });

// Gradient fills
g.fill(new FillGradient({ /* gradient options */ }));
```

### Holes with `.cut()`

```javascript
g.rect(0, 0, 200, 200);
g.circle(100, 100, 50);
g.cut(); // circle becomes a hole in the rect
g.fill(0xff0000);
```

### SVG Path Data

```javascript
g.svg('M 100 100 L 200 100 L 200 200 Z').fill(0x00ff00);
```

### GraphicsContext Reuse

```javascript
const sharedCtx = new GraphicsContext();
sharedCtx.rect(0, 0, 50, 50).fill(0xff0000);

const g1 = new Graphics(sharedCtx);
const g2 = new Graphics(sharedCtx); // reuses same geometry
```

---

## Texture System

### Source Types

| Class | Input | Use Case |
|-------|-------|----------|
| `ImageSource` | HTMLImage, ImageBitmap, SVG | Standard images |
| `CanvasSource` | HTMLCanvas, OffscreenCanvas | Dynamic drawing |
| `VideoSource` | HTMLVideoElement | Video playback |
| `BufferImageSource` | TypedArray, ArrayBuffer | Raw pixel data |
| `CompressedSource` | Compressed arrays | GPU-compressed textures |

### TextureSource Options

```javascript
new TextureSource({
  resource: image,
  resolution: 2,
  format: 'rgba8unorm',
  scaleMode: 'linear',  // or 'nearest'
  wrapMode: 'repeat',   // or 'clamp-to-edge', 'mirror-repeat'
  alphaMode: 'premultiply-alpha-on-upload',
  autoGenerateMipmaps: true, // v8 renamed from 'mipmap'
});
```

### Memory Management

```javascript
Assets.unload('texture.png');    // full cleanup (cache + GPU)
texture.destroy();                // manually-created textures
texture.source.unload();          // GPU only, keep source in memory
```

---

## Text Rendering

### Text (Canvas-based)

```javascript
import { Text, TextStyle } from 'pixi.js';

const style = new TextStyle({
  fontFamily: 'Arial',
  fontSize: 36,
  fill: 0xffffff,
  stroke: { color: 0x000000, width: 4 },
  dropShadow: { color: 0x000000, blur: 4, distance: 2, angle: Math.PI / 6 },
  wordWrap: true,
  wordWrapWidth: 400,
  align: 'center',
});
const text = new Text({ text: 'Hello', style });
```

### BitmapText

```javascript
import { BitmapText, BitmapFont } from 'pixi.js';

// Load font
await Assets.load('fonts/myFont.fnt');

// Or install from TextStyle
BitmapFont.install({ name: 'MyFont', style: { fontSize: 32, fill: 0xffffff } });

const bmpText = new BitmapText({ text: 'Score: 0', style: { fontFamily: 'MyFont', fontSize: 32 } });
```

### HTMLText

```javascript
import { HTMLText } from 'pixi.js';

const htmlText = new HTMLText({
  text: '<b>Bold</b> and <i>italic</i> with <span style="color:red">color</span>',
  style: { fontSize: 24, wordWrap: true, wordWrapWidth: 400 },
});
```

---

## Filters

### Built-in Filters

```javascript
import { BlurFilter, ColorMatrixFilter, DisplacementFilter, NoiseFilter } from 'pixi.js';

sprite.filters = [new BlurFilter({ strength: 8 })];

// ColorMatrix presets
const cm = new ColorMatrixFilter();
cm.grayscale(0.5);   // or .sepia(), .negative(), .brightness(2), .contrast(1.5)
sprite.filters = [cm];
```

### pixi-filters (40+ effects)

```bash
npm install pixi-filters
```

Notable filters: `GlowFilter`, `OutlineFilter`, `DropShadowFilter`, `ShockwaveFilter`, `GodrayFilter`, `CRTFilter`, `GlitchFilter`, `PixelateFilter`, `ASCIIFilter`, `BloomFilter`, `MotionBlurFilter`, `TiltShiftFilter`.

### Advanced Blend Modes

```javascript
import 'pixi.js/advanced-blend-modes';
// Enables: ColorBurnBlend, HardMixBlend, LinearDodgeBlend, etc.
```

---

## Custom Filters

Provide both `glProgram` (WebGL) and `gpuProgram` (WebGPU) for cross-renderer support.

```javascript
import { Filter, GlProgram } from 'pixi.js';

const fragment = `
  in vec2 vTextureCoord;
  uniform sampler2D uTexture;
  uniform float uTime;

  void main() {
    vec2 uv = vTextureCoord;
    uv.x += sin(uv.y * 10.0 + uTime) * 0.02;
    gl_FragColor = texture2D(uTexture, uv);
  }
`;

const myFilter = new Filter({
  glProgram: new GlProgram({ fragment }),
  resources: {
    timeUniforms: {
      uTime: { value: 0.0, type: 'f32' },
    },
  },
});

// Update in ticker
app.ticker.add((ticker) => {
  myFilter.resources.timeUniforms.uniforms.uTime += ticker.deltaTime * 0.01;
});

sprite.filters = [myFilter];
```

---

## Assets System

### Initialization

```javascript
await Assets.init({
  basePath: '/assets/',
  defaultSearchParams: { v: '1.0' },
});
```

### Manifest & Bundles

```javascript
await Assets.init({
  manifest: {
    bundles: [
      { name: 'load-screen', assets: [{ alias: 'bg', src: 'bg.png' }] },
      { name: 'game', assets: [{ alias: 'hero', src: 'hero.png' }] },
    ],
  },
});

await Assets.loadBundle('load-screen');
Assets.backgroundLoadBundle('game'); // load in background
```

### Sprite Sheets

```javascript
const sheet = await Assets.load('spritesheet.json');
const frame = Sprite.from('frameName.png'); // from loaded spritesheet
```

---

## Container API

### Child Management

```javascript
container.addChild(child)
container.addChildAt(child, index)
container.removeChild(child)
container.removeChildAt(index)
container.removeChildren(beginIndex?, endIndex?)
container.swapChildren(child1, child2)
container.reparentChild(child)  // preserves world transform
container.setChildIndex(child, index)
container.getChildAt(index)
container.getChildByLabel(label, deep?)
container.getChildrenByLabel(labelOrRegex, deep?, out?)
```

### Sorting

```javascript
container.sortableChildren = true;
child.zIndex = 10;
container.sortChildren(); // manual sort trigger
```

### Events

```javascript
container.on('childAdded', (child, container, index) => {});
container.on('childRemoved', (child, container, index) => {});
```

---

## Interaction Events

Set `eventMode` before adding listeners:

| Mode | Behavior |
|------|----------|
| `'passive'` | Default. No events. |
| `'static'` | Receives events. Most common for clickable objects. |
| `'dynamic'` | Receives events + fires `mousemove` even when not moving. Rare. |
| `'none'` | Explicitly no events (differs from passive in propagation). |
| `'auto'` | Legacy v7 mode. |

### Common Events

```javascript
sprite.eventMode = 'static';
sprite.on('pointerdown', handler);
sprite.on('pointerup', handler);
sprite.on('pointermove', handler);
sprite.on('pointerover', handler);
sprite.on('pointerout', handler);
sprite.on('pointertap', handler); // click/tap
sprite.on('wheel', handler);
```

### Hit Area

```javascript
import { Rectangle, Circle } from 'pixi.js';

sprite.hitArea = new Rectangle(0, 0, 100, 100);
sprite.hitArea = new Circle(50, 50, 50);
```

---

## Spine Integration

```bash
npm install @pixi-spine/all  # or specific runtime version
```

```javascript
import 'pixi-spine'; // register loaders

const spineData = await Assets.load('skeleton.json');
const spine = new Spine(spineData.spineData);
spine.state.setAnimation(0, 'walk', true);
spine.state.timeScale = 1.5;
app.stage.addChild(spine);
```

v8 Spine: 50% faster rendering, 50% less memory, native WebGPU support, Spine 4.2 physics.

---

## AnimatedSprite

Create frame-based sprite animations from sprite sheets.

### From Spritesheet JSON

```javascript
import { AnimatedSprite, Assets } from 'pixi.js';

const sheet = await Assets.load('character.json');
// Get frames by name pattern
const walkFrames = [];
for (let i = 0; i < 8; i++) {
  walkFrames.push(sheet.textures[`walk_${i}.png`]);
}

const anim = new AnimatedSprite(walkFrames);
anim.anchor.set(0.5);
anim.animationSpeed = 0.15; // frames per tick (0.1–0.3 typical)
anim.play();
app.stage.addChild(anim);
```

### Controls

```javascript
anim.play();
anim.stop();
anim.gotoAndPlay(frameIndex);
anim.gotoAndStop(frameIndex);

anim.loop = false; // play once
anim.onComplete = () => { /* animation finished */ };
anim.onFrameChange = (frame) => { /* frame changed */ };

// Current state
anim.currentFrame; // readonly
anim.playing;      // readonly
anim.totalFrames;  // readonly
```

### Multiple Animations (Swap Textures)

```javascript
const animations = {
  idle: getFrames(sheet, 'idle', 4),
  walk: getFrames(sheet, 'walk', 8),
  attack: getFrames(sheet, 'attack', 6),
};

function playAnimation(sprite, name, speed = 0.15) {
  sprite.textures = animations[name];
  sprite.animationSpeed = speed;
  sprite.play();
}

function getFrames(sheet, prefix, count) {
  return Array.from({ length: count }, (_, i) => sheet.textures[`${prefix}_${i}.png`]);
}
```

---

## ParticleContainer (v8)

Optimized container for rendering thousands of similar objects. Uses `Particle` objects (NOT `Sprite`).

### Setup

```javascript
import { ParticleContainer, Particle, Assets } from 'pixi.js';

const texture = await Assets.load('particle.png');
const particleContainer = new ParticleContainer({
  dynamicProperties: {
    position: true,
    scale: true,
    rotation: true,
    tint: true,
    alpha: true,
  },
});

// Create particles (not sprites!)
for (let i = 0; i < 10000; i++) {
  const particle = new Particle({ texture });
  particle.x = Math.random() * 800;
  particle.y = Math.random() * 600;
  particleContainer.addParticle(particle);
}

app.stage.addChild(particleContainer);
```

### Limitations

- Particles have NO children, NO filters, NO interaction
- Only properties listed in `dynamicProperties` update on GPU
- Cannot use `addChild()` -- use `addParticle()` / `removeParticle()`
- Best for: bullets, rain, snow, stars, background particles (>1000 similar objects)
