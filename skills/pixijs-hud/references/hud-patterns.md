# PixiJS 8.x — HUD Component Patterns

Copy-paste-ready patterns for common game HUD components.

## Table of Contents

- [Health Bar](#health-bar)
- [Score Display](#score-display)
- [Minimap](#minimap)
- [Dialog Box](#dialog-box)
- [Inventory Grid](#inventory-grid)
- [Touch Joystick](#touch-joystick)
- [Damage Numbers](#damage-numbers)
- [Cooldown Indicator](#cooldown-indicator)
- [Notification Toast](#notification-toast)
- [FPS Counter](#fps-counter)

---

## Health Bar

Using @pixi/ui `ProgressBar` with color thresholds:

```javascript
import { ProgressBar } from '@pixi/ui';
import { Graphics, Container, BitmapText } from 'pixi.js';

function createHealthBar(maxHP = 100, width = 200, height = 20) {
  const container = new Container();

  const bg = new Graphics().roundRect(0, 0, width, height, 4).fill(0x222222);
  const fill = new Graphics().roundRect(0, 0, width, height, 4).fill(0x22cc44);

  const bar = new ProgressBar({ bg, fill, progress: 100 });

  const label = new BitmapText({
    text: `${maxHP}/${maxHP}`,
    style: { fontFamily: 'GameFont', fontSize: 14 },
  });
  label.anchor.set(0.5);
  label.position.set(width / 2, height / 2);

  container.addChild(bar, label);

  container.maxHP = maxHP;
  container.currentHP = maxHP;

  container.setHP = function (hp) {
    this.currentHP = Math.max(0, Math.min(hp, this.maxHP));
    const pct = this.currentHP / this.maxHP;
    bar.progress = pct * 100;
    label.text = `${Math.ceil(this.currentHP)}/${this.maxHP}`;

    // Color thresholds
    if (pct > 0.6) fill.tint = 0x22cc44;      // green
    else if (pct > 0.3) fill.tint = 0xccaa22;  // yellow
    else fill.tint = 0xcc2222;                   // red
  };

  container.takeDamage = function (amount) {
    this.setHP(this.currentHP - amount);
  };

  container.heal = function (amount) {
    this.setHP(this.currentHP + amount);
  };

  return container;
}
```

---

## Score Display

BitmapText with animated score counting:

```javascript
import { BitmapText } from 'pixi.js';

function createScoreDisplay(style = { fontFamily: 'GameFont', fontSize: 36 }) {
  const text = new BitmapText({ text: '0', style });

  text.displayedScore = 0;
  text.targetScore = 0;
  text.countSpeed = 5; // points per frame

  text.addScore = function (points) {
    this.targetScore += points;
  };

  text.update = function (dt) {
    if (this.displayedScore < this.targetScore) {
      this.displayedScore = Math.min(
        this.displayedScore + this.countSpeed * dt,
        this.targetScore,
      );
      this.text = Math.floor(this.displayedScore).toLocaleString();
    }
  };

  return text;
}

// Usage in ticker
const score = createScoreDisplay();
app.ticker.add((ticker) => score.update(ticker.deltaTime));
score.addScore(500); // score counts up smoothly
```

---

## Minimap

RenderTexture-based minimap with entity dots:

```javascript
import { Container, Graphics, RenderTexture, Sprite } from 'pixi.js';

function createMinimap(worldW, worldH, mapW = 150, mapH = 100) {
  const container = new Container();
  const scaleX = mapW / worldW;
  const scaleY = mapH / worldH;

  // Background
  const bg = new Graphics()
    .rect(0, 0, mapW, mapH).fill(0x111111)
    .rect(0, 0, mapW, mapH).stroke({ color: 0x888888, width: 1 });
  container.addChild(bg);

  // Dot layer (redrawn each update)
  const dots = new Graphics();
  container.addChild(dots);

  // Update frequency control
  let frameCount = 0;

  container.updateMinimap = function (entities, player) {
    frameCount++;
    if (frameCount % 6 !== 0) return; // update every 6 frames

    dots.clear();

    // Draw entities as colored dots
    for (const e of entities) {
      const color = e.type === 'enemy' ? 0xff4444 : 0x44ff44;
      dots.circle(e.x * scaleX, e.y * scaleY, 2).fill(color);
    }

    // Player dot (larger, white)
    dots.circle(player.x * scaleX, player.y * scaleY, 3).fill(0xffffff);

    // Viewport rectangle
    const cam = { x: player.x - 400, y: player.y - 300, w: 800, h: 600 };
    dots.rect(cam.x * scaleX, cam.y * scaleY, cam.w * scaleX, cam.h * scaleY)
      .stroke({ color: 0xffffff, width: 1, alpha: 0.5 });
  };

  return container;
}
```

---

## Dialog Box

NineSlice-based dialog with typewriter text effect:

```javascript
import { Container, NineSliceSprite, BitmapText, Assets } from 'pixi.js';

function createDialogBox(width = 600, height = 150) {
  const container = new Container();
  container.visible = false;

  // NineSlice panel (load a 9-slice texture first)
  // Or use Graphics for simple style:
  const panel = new Graphics()
    .roundRect(0, 0, width, height, 12).fill({ color: 0x1a1a2e, alpha: 0.9 })
    .roundRect(0, 0, width, height, 12).stroke({ color: 0x4466aa, width: 2 });
  container.addChild(panel);

  const nameText = new BitmapText({
    text: '',
    style: { fontFamily: 'GameFont', fontSize: 20, fill: 0x66aaff },
  });
  nameText.position.set(16, 12);
  container.addChild(nameText);

  const bodyText = new BitmapText({
    text: '',
    style: { fontFamily: 'GameFont', fontSize: 16 },
  });
  bodyText.position.set(16, 40);
  container.addChild(bodyText);

  // Typewriter state
  let fullText = '';
  let charIndex = 0;
  let typeSpeed = 2; // chars per frame
  let onComplete = null;

  container.show = function (speaker, message, speed = 2, callback = null) {
    nameText.text = speaker;
    fullText = message;
    charIndex = 0;
    typeSpeed = speed;
    onComplete = callback;
    bodyText.text = '';
    this.visible = true;
  };

  container.update = function (dt) {
    if (!this.visible || charIndex >= fullText.length) return;
    charIndex = Math.min(charIndex + typeSpeed * dt, fullText.length);
    bodyText.text = fullText.slice(0, Math.floor(charIndex));
    if (charIndex >= fullText.length && onComplete) onComplete();
  };

  container.skip = function () {
    charIndex = fullText.length;
    bodyText.text = fullText;
    if (onComplete) onComplete();
  };

  container.hide = function () {
    this.visible = false;
  };

  return container;
}

// Usage
const dialog = createDialogBox();
dialog.position.set(160, 500);
hudLayer.addChild(dialog);
dialog.show('NPC', 'Welcome to the village! There are monsters in the forest...');
app.ticker.add((ticker) => dialog.update(ticker.deltaTime));
```

---

## Inventory Grid

Grid layout with selectable slots:

```javascript
import { Container, Graphics, Sprite } from 'pixi.js';

function createInventoryGrid(cols = 5, rows = 4, cellSize = 64, gap = 4) {
  const container = new Container();
  const slots = [];
  let selectedIndex = -1;

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const index = r * cols + c;
      const x = c * (cellSize + gap);
      const y = r * (cellSize + gap);

      const slot = new Container();
      slot.position.set(x, y);

      const bg = new Graphics()
        .roundRect(0, 0, cellSize, cellSize, 4).fill(0x2a2a3e)
        .roundRect(0, 0, cellSize, cellSize, 4).stroke({ color: 0x444466, width: 1 });

      slot.addChild(bg);
      slot.bg = bg;
      slot.item = null;
      slot.index = index;

      // Interaction
      slot.eventMode = 'static';
      slot.cursor = 'pointer';
      slot.hitArea = { x: 0, y: 0, width: cellSize, height: cellSize, contains: (px, py) => px >= 0 && px <= cellSize && py >= 0 && py <= cellSize };

      slot.on('pointertap', () => {
        if (selectedIndex >= 0) slots[selectedIndex].bg.tint = 0xffffff;
        selectedIndex = index;
        slot.bg.tint = 0x66aaff;
        container.emit('slot-select', { index, item: slot.item });
      });

      container.addChild(slot);
      slots.push(slot);
    }
  }

  container.setItem = function (index, texture) {
    const slot = slots[index];
    if (slot.itemSprite) slot.removeChild(slot.itemSprite);
    if (texture) {
      const sprite = new Sprite(texture);
      sprite.width = cellSize - 8;
      sprite.height = cellSize - 8;
      sprite.position.set(4, 4);
      slot.addChild(sprite);
      slot.itemSprite = sprite;
      slot.item = texture;
    } else {
      slot.item = null;
    }
  };

  container.clearSlot = function (index) {
    this.setItem(index, null);
  };

  container.getSelectedIndex = function () {
    return selectedIndex;
  };

  return container;
}
```

---

## Touch Joystick

Virtual joystick for mobile controls:

```javascript
import { Container, Graphics } from 'pixi.js';

function createJoystick(radius = 60, knobRadius = 25) {
  const container = new Container();
  container.eventMode = 'static';

  // Outer ring
  const ring = new Graphics()
    .circle(0, 0, radius).fill({ color: 0xffffff, alpha: 0.15 })
    .circle(0, 0, radius).stroke({ color: 0xffffff, alpha: 0.3, width: 2 });

  // Inner knob
  const knob = new Graphics()
    .circle(0, 0, knobRadius).fill({ color: 0xffffff, alpha: 0.4 });

  container.addChild(ring, knob);

  // State: normalized -1..1
  container.dx = 0;
  container.dy = 0;
  container.active = false;

  let pointerId = null;

  container.hitArea = { contains: (x, y) => x * x + y * y <= radius * radius };

  container.on('pointerdown', (e) => {
    pointerId = e.pointerId;
    container.active = true;
    updateKnob(e);
  });

  container.on('globalpointermove', (e) => {
    if (e.pointerId !== pointerId || !container.active) return;
    updateKnob(e);
  });

  container.on('pointerup', release);
  container.on('pointerupoutside', release);

  function updateKnob(e) {
    const local = container.toLocal(e.global);
    const dist = Math.sqrt(local.x * local.x + local.y * local.y);
    const clamped = Math.min(dist, radius);
    const angle = Math.atan2(local.y, local.x);

    knob.x = Math.cos(angle) * clamped;
    knob.y = Math.sin(angle) * clamped;

    container.dx = knob.x / radius; // -1..1
    container.dy = knob.y / radius; // -1..1
  }

  function release() {
    pointerId = null;
    container.active = false;
    knob.x = 0;
    knob.y = 0;
    container.dx = 0;
    container.dy = 0;
  }

  return container;
}

// Usage
const joystick = createJoystick();
joystick.position.set(120, screenH - 120);
hudLayer.addChild(joystick);

app.ticker.add((ticker) => {
  player.x += joystick.dx * speed * ticker.deltaTime;
  player.y += joystick.dy * speed * ticker.deltaTime;
});
```

---

## Damage Numbers

Pooled floating text that drifts upward and fades:

```javascript
import { BitmapText, Container } from 'pixi.js';

function createDamageNumberPool(poolSize = 20) {
  const container = new Container();
  const pool = [];

  for (let i = 0; i < poolSize; i++) {
    const num = new BitmapText({
      text: '',
      style: { fontFamily: 'GameFont', fontSize: 24 },
    });
    num.anchor.set(0.5);
    num.visible = false;
    num.vy = 0;
    num.life = 0;
    container.addChild(num);
    pool.push(num);
  }

  container.spawn = function (x, y, amount, color = 0xffffff) {
    const num = pool.find((n) => !n.visible);
    if (!num) return; // pool exhausted

    num.text = amount > 0 ? `+${amount}` : `${amount}`;
    num.tint = color;
    num.position.set(x + (Math.random() - 0.5) * 20, y);
    num.alpha = 1;
    num.scale.set(1);
    num.vy = -2; // float up speed
    num.life = 60; // frames
    num.visible = true;
  };

  container.update = function (dt) {
    for (const num of pool) {
      if (!num.visible) continue;
      num.y += num.vy * dt;
      num.life -= dt;
      num.alpha = Math.max(0, num.life / 60);
      num.scale.set(0.8 + 0.2 * (num.life / 60));
      if (num.life <= 0) num.visible = false;
    }
  };

  return container;
}

// Usage
const dmgNumbers = createDamageNumberPool();
hudLayer.addChild(dmgNumbers);
app.ticker.add((ticker) => dmgNumbers.update(ticker.deltaTime));

// On hit:
dmgNumbers.spawn(enemy.x, enemy.y - 20, -42, 0xff4444);  // red damage
dmgNumbers.spawn(player.x, player.y - 20, 15, 0x44ff44); // green heal
```

---

## Cooldown Indicator

Circular cooldown overlay on an ability icon:

```javascript
import { Container, Graphics, Sprite } from 'pixi.js';

function createCooldownIcon(texture, size = 48) {
  const container = new Container();

  const icon = new Sprite(texture);
  icon.width = size;
  icon.height = size;
  container.addChild(icon);

  // Cooldown overlay (drawn as pie slice)
  const overlay = new Graphics();
  container.addChild(overlay);

  container.cooldownTotal = 0;
  container.cooldownRemaining = 0;

  container.startCooldown = function (seconds) {
    this.cooldownTotal = seconds;
    this.cooldownRemaining = seconds;
    icon.tint = 0x666666;
  };

  container.update = function (dt) {
    if (this.cooldownRemaining <= 0) return;

    this.cooldownRemaining -= dt / 60; // assuming 60fps ticker
    if (this.cooldownRemaining <= 0) {
      this.cooldownRemaining = 0;
      icon.tint = 0xffffff;
      overlay.clear();
      return;
    }

    const pct = this.cooldownRemaining / this.cooldownTotal;
    const angle = pct * Math.PI * 2;
    const cx = size / 2;
    const cy = size / 2;

    overlay.clear();
    overlay.moveTo(cx, cy);
    overlay.arc(cx, cy, size / 2, -Math.PI / 2, -Math.PI / 2 + angle);
    overlay.lineTo(cx, cy);
    overlay.fill({ color: 0x000000, alpha: 0.6 });
  };

  return container;
}
```

---

## Notification Toast

Slide-in notification that auto-dismisses:

```javascript
import { Container, Graphics, BitmapText } from 'pixi.js';

function createToastSystem(screenW) {
  const container = new Container();
  const queue = [];
  let active = null;

  function showNext() {
    if (queue.length === 0 || active) return;
    active = queue.shift();

    const bg = new Graphics()
      .roundRect(0, 0, 300, 40, 6).fill({ color: 0x222244, alpha: 0.9 });
    const text = new BitmapText({
      text: active.message,
      style: { fontFamily: 'GameFont', fontSize: 16 },
    });
    text.position.set(12, 10);

    const toast = new Container();
    toast.addChild(bg, text);
    toast.position.set(screenW / 2 - 150, -50); // start above screen
    toast.targetY = 16;
    toast.life = 180; // 3 seconds at 60fps
    toast.phase = 'in'; // in → hold → out

    container.addChild(toast);
    active.toast = toast;
  }

  container.notify = function (message) {
    queue.push({ message });
    if (!active) showNext();
  };

  container.update = function (dt) {
    if (!active) return;
    const t = active.toast;

    if (t.phase === 'in') {
      t.y += (t.targetY - t.y) * 0.15 * dt;
      if (Math.abs(t.y - t.targetY) < 1) { t.y = t.targetY; t.phase = 'hold'; }
    } else if (t.phase === 'hold') {
      t.life -= dt;
      if (t.life <= 0) t.phase = 'out';
    } else {
      t.y -= 3 * dt;
      t.alpha -= 0.05 * dt;
      if (t.alpha <= 0) {
        container.removeChild(t);
        t.destroy({ children: true });
        active = null;
        showNext();
      }
    }
  };

  return container;
}
```

---

## FPS Counter

Lightweight debug display:

```javascript
import { BitmapText } from 'pixi.js';

function createFPSCounter() {
  const text = new BitmapText({
    text: 'FPS: 60',
    style: { fontFamily: 'GameFont', fontSize: 14, fill: 0x44ff44 },
  });
  text.alpha = 0.7;

  let frames = 0;
  let elapsed = 0;

  text.update = function (dt) {
    frames++;
    elapsed += dt;
    if (elapsed >= 60) { // update every ~1 second
      const fps = Math.round(frames / (elapsed / 60));
      this.text = `FPS: ${fps}`;
      this.tint = fps >= 55 ? 0x44ff44 : fps >= 30 ? 0xffaa44 : 0xff4444;
      frames = 0;
      elapsed = 0;
    }
  };

  return text;
}
```
