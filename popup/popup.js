(function initializePopup() {
  "use strict";

  const Core = globalThis.WheelSeekCore;
  const seekSlider = document.getElementById("seek-seconds");
  const seekValue = document.getElementById("seek-value");
  const variableSeek = document.getElementById("variable-seek");
  const broadcastClock = document.getElementById("broadcast-clock");
  const saveStatus = document.getElementById("save-status");
  let saveStatusTimer = null;

  function localize() {
    for (const element of document.querySelectorAll("[data-i18n]")) {
      const message = chrome.i18n.getMessage(element.dataset.i18n);

      if (message) {
        element.textContent = message;
      }
    }

    document.documentElement.lang = chrome.i18n.getUILanguage().split("-")[0];
  }

  function updateSeekValue() {
    seekValue.value = `${seekSlider.value}s`;
    seekValue.textContent = `${seekSlider.value}s`;
  }

  function announceSaved() {
    saveStatus.textContent = chrome.i18n.getMessage("saved") || "Saved";
    clearTimeout(saveStatusTimer);
    saveStatusTimer = setTimeout(() => {
      saveStatus.textContent = "";
    }, 900);
  }

  async function save() {
    const next = Core.sanitizeSettings({
      seekSeconds: seekSlider.value,
      variableSeekEnabled: variableSeek.checked,
      broadcastClockEnabled: broadcastClock.checked
    });

    await chrome.storage.sync.set(next);
    announceSaved();
  }

  async function load() {
    const stored = await chrome.storage.sync.get(
      Object.keys(Core.DEFAULT_SETTINGS)
    );
    const current = Core.sanitizeSettings(stored);

    seekSlider.value = String(current.seekSeconds);
    variableSeek.checked = current.variableSeekEnabled;
    broadcastClock.checked = current.broadcastClockEnabled;
    updateSeekValue();
  }

  seekSlider.addEventListener("input", updateSeekValue);
  seekSlider.addEventListener("change", () => void save());
  variableSeek.addEventListener("change", () => void save());
  broadcastClock.addEventListener("change", () => void save());

  localize();
  load().catch(() => {
    updateSeekValue();
  });
})();
