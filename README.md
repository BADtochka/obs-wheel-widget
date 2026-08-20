# ETS Steering OBS Widget

A transparent OBS Browser Source that reacts to a gamepad steering axis.

## Install

1. Put your picture into this folder as `image.png`.
2. In OBS: **Sources → + → Browser**.
3. Enable **Local file** and choose `index.html`.
4. Set the Browser Source size to match your canvas, e.g. **1920×1080**.
5. Enable **Use custom frame rate → 60 FPS** for smoother motion/shake.
6. Move the gamepad stick/wheel. The first connected gamepad is used automatically.

OBS Browser Source is CEF-based, and Gamepad API overlays are commonly used directly inside OBS Browser Source.

## If steering does not react

Set `debug: true` in `config.js`. The debug panel shows every gamepad axis, steering speed and shake amount. You can also use `?debug=1` when opening the page in a normal browser.

Turn the steering control and find which axis changes from roughly `-1` to `+1`, then set it in `config.js`:

```js
steeringAxis: 0,
```

Typical XInput left-stick X is axis `0`.

## Main tuning

Edit `config.js`:

- `debug` — show/hide the live controller diagnostics.
- `maxRotateDeg` — image rotation at full steering lock.
- `maxMoveXpx` — horizontal movement at full lock.
- `smoothing` — steering smoothing.
- `deadzone` — ignores controller noise near center.
- `shakeStartSpeed` — how fast the steering must move before shake starts.
- `shakeFullSpeed` — speed that gives maximum shake.
- `shakeMaxXpx`, `shakeMaxYpx`, `shakeMaxRotateDeg` — shake strength.
- `shakeAttack`, `shakeDecay` — how quickly shake appears/disappears.
- `invert` — reverse steering direction.

## Recommended starting values

The included config is tuned so normal steering is smooth, while a fast flick/rapid correction triggers visible shake.

If shake happens too often, raise `shakeStartSpeed` from `2.6` to `3.5–4.5`.
If it almost never happens, lower it to `1.8–2.2`.
