# PixiJS v7 → v8 Migration Guide

## Table of Contents

- [Breaking Changes Summary](#breaking-changes-summary)
- [Initialization](#initialization)
- [Imports](#imports)
- [Graphics API](#graphics-api)
- [Textures](#textures)
- [Containers & Display Objects](#containers--display-objects)
- [Constructor Style](#constructor-style)
- [Ticker](#ticker)
- [Shaders](#shaders)
- [Other Changes](#other-changes)

---

## Breaking Changes Summary

| v7 | v8 | Notes |
|----|-----|-------|
| `new Application({ ... })` | `await app.init({ ... })` | Async required |
| Multi-package imports | `import { ... } from 'pixi.js'` | Single package |
| `beginFill().drawRect().endFill()` | `.rect().fill()` | Chainable builder |
| `BaseTexture` | `TextureSource` / `ImageSource` / etc. | Removed |
| `Texture.from(url)` | `await Assets.load(url)` | Must pre-load |
| `app.view` | `app.canvas` | Renamed |
| `container.name` | `container.label` | Renamed |
| `cacheAsBitmap` | `cacheAsTexture()` | Method, not property |
| `updateTransform()` | `onRender()` | Callback pattern |
| `mipmap` property | `autoGenerateMipmaps` | Renamed |
| `getBounds()` returns Rectangle | `getBounds().rectangle` | Returns Bounds object |
| `utils.hex2string()` etc. | Import directly | `utils` module removed |
| `PIXI.settings` | `AbstractRenderer.defaultOptions` | Settings removed |
| Sprites can have children | Only Container can | Leaf node restriction |
| Ticker delta param | Ticker instance param | `(ticker) => ticker.deltaTime` |
| Constructor positional args | Config objects | `{ strength: 8 }` |
| Event mode `'auto'` default | `'passive'` default | Must opt-in to events |

## Initialization

```javascript
// v7
const app = new Application({ width: 800, height: 600 });
document.body.appendChild(app.view);

// v8
const app = new Application();
await app.init({ width: 800, height: 600 });
document.body.appendChild(app.canvas);
```

## Imports

```javascript
// v7
import { Sprite } from '@pixi/sprite';
import { Graphics } from '@pixi/graphics';

// v8
import { Sprite, Graphics } from 'pixi.js';
```

## Graphics API

```javascript
// v7
graphics.beginFill(0xff0000);
graphics.drawRect(0, 0, 200, 100);
graphics.endFill();
graphics.lineStyle(2, 0x000000);
graphics.drawCircle(100, 100, 50);

// v8
graphics.rect(0, 0, 200, 100).fill(0xff0000);
graphics.circle(100, 100, 50).stroke({ color: 0x000000, width: 2 });
```

## Textures

```javascript
// v7
const texture = Texture.from('image.png'); // sync, lazy load

// v8
const texture = await Assets.load('image.png'); // must pre-load
const sprite = new Sprite(texture);
```

`BaseTexture` is removed. Use specific source types:
- `ImageSource` — images, SVG
- `CanvasSource` — canvas elements
- `VideoSource` — video
- `BufferImageSource` — raw pixel data

## Containers & Display Objects

```javascript
// v7 — sprites could have children
sprite.addChild(otherSprite); // worked

// v8 — only Container can have children
const group = new Container();
group.addChild(sprite, otherSprite);
```

```javascript
// v7
container.name = 'player';
container.cacheAsBitmap = true;

// v8
container.label = 'player';
container.cacheAsTexture();
```

## Constructor Style

```javascript
// v7
new BlurFilter(8, 4);
new Sprite(texture);

// v8
new BlurFilter({ strength: 8, quality: 4 });
new Sprite(texture); // Sprite unchanged, but most other classes use config objects
```

## Ticker

```javascript
// v7
app.ticker.add((delta) => {
  sprite.rotation += 0.1 * delta;
});

// v8
app.ticker.add((ticker) => {
  sprite.rotation += 0.1 * ticker.deltaTime;
});
```

## Shaders

```javascript
// v7
const shader = Shader.from(vertexSrc, fragmentSrc, uniforms);

// v8
const shader = Shader.from({
  gl: { vertex: vertexSrc, fragment: fragmentSrc },
  gpu: { vertex: gpuVertex, fragment: gpuFragment },
  resources: {
    myUniforms: {
      uTime: { value: 0.0, type: 'f32' },
    },
  },
});
```

## Other Changes

- **ParticleContainer**: Only accepts `Particle` objects (not `Sprite`). Use `particleChildren` property.
- **`getBounds()`**: Returns `Bounds` object. Access rectangle via `.rectangle`.
- **`updateTransform()`**: Removed. Use `onRender()` callback for per-frame logic.
- **Advanced blend modes**: Require explicit import: `import 'pixi.js/advanced-blend-modes'`
- **Event mode**: Default is `'passive'`. Set `eventMode = 'static'` on interactive objects.
