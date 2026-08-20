(() => {
  const keyboardKeys = new Set();

  window.addEventListener("etsSteeringKeyboard", (event) => {
    const detail = event.detail;
    if (!detail || (detail.direction !== -1 && detail.direction !== 1) || typeof detail.pressed !== "boolean") {
      return;
    }

    const key = detail.direction < 0 ? "obs-left" : "obs-right";
    if (detail.pressed) keyboardKeys.add(key);
    else keyboardKeys.delete(key);

    window.dispatchEvent(new CustomEvent("etsSteeringKeyboardState", { detail: keyboardKeys }));
  });
})();
