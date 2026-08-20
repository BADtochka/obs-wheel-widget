window.STEERING_WIDGET_CONFIG = {
  // Image placed next to index.html. PNG/WebP/GIF/SVG all work.
  image: "image.png",

  // Shows controller id, axes, steering speed and shake strength.
  debug: false,

  // Standard gamepads usually expose left-stick X as axis 0.
  // Open index.html?debug=1 in a browser/OBS interaction window to inspect axes.
  steeringAxis: 0,
  invert: true,
  keyboardEnabled: true,

  // Ignore tiny stick/wheel noise around center.
  deadzone: 0.02,

  // Steering visual response.
  maxRotateDeg: 20.0,
  maxMoveXpx: 72,
  maxMoveYpx: 7,
  steerExpo: 0.8,
  smoothing: 0.28,

  // Slight scale prevents transparent gaps while the image moves/shakes.
  baseScale: 1.06,

  // Shake starts from steering angular velocity (axis units / second).
  // Full left -> full right in 0.5 s is roughly 4 units/s.
  shakeStartSpeed: 0.8,
  shakeFullSpeed: 3.5,
  shakeMaxXpx: 32,
  shakeMaxYpx: 20,
  shakeMaxRotateDeg: 5.0,
  shakeAttack: 0.72,
  shakeDecay: 0.2,

  // Prevent tiny corrections near center from triggering shake.
  shakeMinSteer: 0.12,

  // null = first connected gamepad. Set 0/1/... to force one.
  gamepadIndex: null
};
