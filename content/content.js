(function initializeWheelSeek() {
  "use strict";

  const Core = globalThis.WheelSeekCore;
  const YouTubeMetadata = globalThis.WheelSeekYouTubeMetadata;
  const STORAGE_KEYS = Object.keys(Core.DEFAULT_SETTINGS);
  const WHEEL_THRESHOLD_PX = 50;
  const VARIABLE_WINDOW_MS = 250;
  const MIN_SEEK_INTERVAL_MS = 70;
  const OVERLAY_DURATION_MS = 1750;
  const LIVE_DVR_MINIMUM_SECONDS = 30;
  const TWITCH_DVR_ACTIVATION_POLL_MS = 50;
  const TWITCH_DVR_ACTIVATION_TIMEOUT_MS = 1000;
  const YOUTUBE_METADATA_SOURCE = "wheelseek-page-metadata";
  const TWITCH_RESERVED_SEGMENTS = new Set([
    "directory",
    "downloads",
    "drops",
    "inventory",
    "jobs",
    "p",
    "search",
    "settings",
    "subscriptions",
    "turbo",
    "wallet"
  ]);

  let settings = { ...Core.DEFAULT_SETTINGS };
  let wheelAccumulator = 0;
  let lastSeekAt = 0;
  let recentWheelSamples = [];
  let overlayTimer = null;
  let youtubeMetadata = null;

  function isVisible(element) {
    if (!(element instanceof Element)) {
      return false;
    }

    const rect = element.getBoundingClientRect();
    const style = getComputedStyle(element);
    return (
      rect.width > 40 &&
      rect.height > 4 &&
      style.display !== "none" &&
      style.visibility !== "hidden" &&
      Number(style.opacity) !== 0
    );
  }

  function getVisibleVideosAtPoint(x, y) {
    return [...document.querySelectorAll("video")]
      .filter((video) => {
        const rect = video.getBoundingClientRect();
        return (
          rect.width >= 160 &&
          rect.height >= 90 &&
          x >= rect.left &&
          x <= rect.right &&
          y >= rect.top &&
          y <= rect.bottom &&
          isVisible(video)
        );
      })
      .sort((a, b) => {
        const areaA = a.getBoundingClientRect().width * a.getBoundingClientRect().height;
        const areaB = b.getBoundingClientRect().width * b.getBoundingClientRect().height;
        return areaB - areaA;
      });
  }

  function isYouTube() {
    return location.hostname === "www.youtube.com" || location.hostname === "m.youtube.com";
  }

  function isTwitch() {
    return location.hostname === "www.twitch.tv";
  }

  function getCurrentYouTubeMetadata() {
    return YouTubeMetadata.metadataMatchesUrl(youtubeMetadata, location.href)
      ? youtubeMetadata
      : null;
  }

  function isTwitchLiveSession() {
    if (!isTwitch() || !/^\/[^/]+\/?$/.test(location.pathname)) {
      return false;
    }

    const channel = location.pathname.split("/").filter(Boolean)[0] || "";
    return !TWITCH_RESERVED_SEGMENTS.has(channel.toLowerCase());
  }

  function isSupportedPath() {
    if (isYouTube()) {
      return location.pathname === "/watch" || location.pathname.startsWith("/live/");
    }

    if (isTwitch()) {
      const firstSegment = location.pathname.split("/").filter(Boolean)[0] || "";

      return (
        location.pathname.startsWith("/videos/") ||
        (/^\/[^/]+\/?$/.test(location.pathname) &&
          !TWITCH_RESERVED_SEGMENTS.has(firstSegment.toLowerCase()))
      );
    }

    return false;
  }

  function hasVisibleSiteSeekbar() {
    const selectors = isYouTube()
      ? [
          ".ytp-progress-bar[role='slider']",
          ".ytp-progress-bar-container"
        ]
      : [
          "[data-a-target='player-seekbar']",
          "[data-a-target*='seekbar']",
          "[data-test-selector*='seekbar']",
          "input[type='range'][aria-label*='seek' i]"
        ];

    return selectors.some((selector) =>
      [...document.querySelectorAll(selector)].some(isVisible)
    );
  }

  function isAdvertisementPlaying(video) {
    if (isYouTube()) {
      return Boolean(video.closest(".ad-showing, .ad-interrupting"));
    }

    if (isTwitch()) {
      return Boolean(
        document.querySelector(
          "[data-a-target='video-ad-label'], [data-test-selector='video-ad-overlay']"
        )
      );
    }

    return false;
  }

  function isProbablyLive(video) {
    if (isYouTube()) {
      const currentMetadata = getCurrentYouTubeMetadata();
      return (
        currentMetadata?.isLive === true ||
        !Number.isFinite(video.duration) ||
        video.duration === Infinity
      );
    }

    return (
      isTwitchLiveSession() ||
      !Number.isFinite(video.duration) ||
      video.duration === Infinity
    );
  }

  function canSeek(video) {
    if (!isSupportedPath() || isAdvertisementPlaying(video) || !hasVisibleSiteSeekbar()) {
      return false;
    }

    const bounds = Core.getSeekBounds(video);

    if (!bounds) {
      return false;
    }

    if (isProbablyLive(video) && bounds.span < LIVE_DVR_MINIMUM_SECONDS) {
      return false;
    }

    return true;
  }

  function getTwitchStartTimestamp() {
    const metaSelectors = [
      "meta[property='og:video:release_date']",
      "meta[property='video:release_date']",
      "meta[itemprop='uploadDate']",
      "meta[name='date']"
    ];

    for (const selector of metaSelectors) {
      const value = document.querySelector(selector)?.content;

      if (value && Number.isFinite(Date.parse(value))) {
        return value;
      }
    }

    for (const script of document.querySelectorAll("script[type='application/ld+json']")) {
      try {
        const parsed = JSON.parse(script.textContent);
        const candidates = Array.isArray(parsed) ? parsed : [parsed];

        for (const candidate of candidates) {
          const value = candidate?.startDate || candidate?.uploadDate || candidate?.datePublished;

          if (value && Number.isFinite(Date.parse(value))) {
            return value;
          }
        }
      } catch {
        // Ignore unrelated or malformed structured data.
      }
    }

    return null;
  }

  function getBroadcastDate(video, bounds) {
    if (isYouTube()) {
      const currentMetadata = getCurrentYouTubeMetadata();

      if (
        currentMetadata?.isLiveContent === true &&
        currentMetadata.startTimestamp
      ) {
        return Core.broadcastClockDate(
          currentMetadata.startTimestamp,
          Date.now(),
          video.currentTime,
          bounds.end
        );
      }
    }

    if (
      isTwitchLiveSession() &&
      Core.isOpenEndedLiveRange(video.duration, bounds)
    ) {
      return new Date();
    }

    if (isProbablyLive(video)) {
      return Core.liveClockDate(Date.now(), video.currentTime, bounds.end);
    }

    let startTimestamp = null;

    if (isTwitch()) {
      startTimestamp = getTwitchStartTimestamp();
    }

    if (!startTimestamp) {
      return null;
    }

    return Core.archiveClockDate(startTimestamp, video.currentTime);
  }

  function ensureOverlay() {
    let overlay = document.getElementById("wheelseek-overlay");

    if (overlay) {
      return overlay;
    }

    overlay = document.createElement("div");
    overlay.id = "wheelseek-overlay";
    overlay.setAttribute("role", "status");
    overlay.setAttribute("aria-live", "polite");
    overlay.innerHTML =
      '<span class="wheelseek-date"></span>' +
      '<span class="wheelseek-clock"></span>' +
      '<span class="wheelseek-seek"></span>';
    document.documentElement.append(overlay);
    return overlay;
  }

  function positionOverlay(overlay, video) {
    const rect = video.getBoundingClientRect();
    const horizontalCenter = Core.clamp(
      rect.left + rect.width / 2,
      120,
      window.innerWidth - 120
    );
    const top = Math.max(12, rect.top + Math.min(28, rect.height * 0.08));

    overlay.style.left = `${horizontalCenter}px`;
    overlay.style.top = `${top}px`;
  }

  function showOverlay(video, signedSeconds, bounds) {
    const overlay = ensureOverlay();
    const date = overlay.querySelector(".wheelseek-date");
    const clock = overlay.querySelector(".wheelseek-clock");
    const seek = overlay.querySelector(".wheelseek-seek");
    const direction = signedSeconds > 0 ? "+" : "−";
    const broadcastDate = settings.broadcastClockEnabled
      ? getBroadcastDate(video, bounds)
      : null;
    const formattedDateTime = broadcastDate
      ? Core.formatLocalDateTime(broadcastDate)
      : null;
    const [dateText, timeText] = formattedDateTime
      ? formattedDateTime.split(" ")
      : ["", ""];

    date.textContent = dateText;
    date.hidden = !formattedDateTime;
    clock.textContent = formattedDateTime
      ? timeText
      : `${direction}${Math.abs(signedSeconds)}s`;
    seek.textContent = formattedDateTime
      ? `${direction}${Math.abs(signedSeconds)}s`
      : "";
    positionOverlay(overlay, video);
    overlay.classList.add("wheelseek-visible");

    clearTimeout(overlayTimer);
    overlayTimer = setTimeout(() => {
      overlay.classList.remove("wheelseek-visible");
    }, OVERLAY_DURATION_MS);
  }

  function pruneWheelSamples(now) {
    recentWheelSamples = recentWheelSamples.filter(
      (sample) => now - sample.at <= VARIABLE_WINDOW_MS
    );
  }

  function recordWheelSample(now, delta) {
    recentWheelSamples.push({ at: now, amount: Math.abs(delta) });
    pruneWheelSamples(now);
    return recentWheelSamples.reduce((sum, sample) => sum + sample.amount, 0);
  }

  function dispatchTwitchDvrShortcut(video) {
    const eventOptions = {
      key: "ArrowLeft",
      code: "ArrowLeft",
      keyCode: 37,
      which: 37,
      bubbles: true,
      cancelable: true
    };

    video.dispatchEvent(new KeyboardEvent("keydown", eventOptions));
    video.dispatchEvent(new KeyboardEvent("keyup", eventOptions));
  }

  function seekFromTwitchLiveEdge(video, signedSeconds) {
    dispatchTwitchDvrShortcut(video);
    const activationStartedAt = performance.now();

    function applySeekAfterActivation() {
      const refreshedBounds = Core.getSeekBounds(video);

      if (!refreshedBounds) {
        return;
      }

      if (Core.isOpenEndedLiveRange(video.duration, refreshedBounds)) {
        if (
          performance.now() - activationStartedAt <
          TWITCH_DVR_ACTIVATION_TIMEOUT_MS
        ) {
          setTimeout(applySeekAfterActivation, TWITCH_DVR_ACTIVATION_POLL_MS);
        }
        return;
      }

      const target = Core.resolveSeekTarget(
        refreshedBounds.end,
        signedSeconds,
        refreshedBounds
      );

      if (target === null) {
        return;
      }

      video.currentTime = target;
      showOverlay(video, signedSeconds, refreshedBounds);
    }

    setTimeout(applySeekAfterActivation, TWITCH_DVR_ACTIVATION_POLL_MS);
  }

  function handleWheel(event) {
    const [video] = getVisibleVideosAtPoint(event.clientX, event.clientY);

    if (!video || !canSeek(video)) {
      wheelAccumulator = 0;
      return;
    }

    const delta = Core.normalizeWheelDelta(event, window.innerHeight);

    if (delta === 0) {
      return;
    }

    event.preventDefault();
    event.stopPropagation();

    const now = performance.now();

    if (wheelAccumulator !== 0 && Math.sign(wheelAccumulator) !== Math.sign(delta)) {
      wheelAccumulator = 0;
      recentWheelSamples = [];
    }

    const recentAbsoluteDelta = recordWheelSample(now, delta);
    wheelAccumulator += delta;

    if (
      Math.abs(wheelAccumulator) < WHEEL_THRESHOLD_PX ||
      now - lastSeekAt < MIN_SEEK_INTERVAL_MS
    ) {
      return;
    }

    const bounds = Core.getSeekBounds(video);
    const amount = Core.seekSecondsForInput(
      settings,
      event.shiftKey,
      recentAbsoluteDelta
    );
    const signedSeconds = Math.sign(wheelAccumulator) < 0 ? amount : -amount;
    wheelAccumulator = 0;

    if (
      isTwitchLiveSession() &&
      Core.isOpenEndedLiveRange(video.duration, bounds)
    ) {
      if (signedSeconds < 0) {
        lastSeekAt = now;
        seekFromTwitchLiveEdge(video, signedSeconds);
      }
      return;
    }

    const target = Core.resolveSeekTarget(video.currentTime, signedSeconds, bounds);

    if (target === null || Math.abs(target - video.currentTime) < 0.01) {
      return;
    }

    lastSeekAt = now;
    video.currentTime = target;
    showOverlay(video, signedSeconds, bounds);
  }

  async function loadSettings() {
    const saved = await chrome.storage.sync.get(STORAGE_KEYS);
    settings = Core.sanitizeSettings(saved);
  }

  chrome.storage.onChanged.addListener((changes, areaName) => {
    if (areaName !== "sync") {
      return;
    }

    const next = { ...settings };

    for (const key of STORAGE_KEYS) {
      if (changes[key]) {
        next[key] = changes[key].newValue;
      }
    }

    settings = Core.sanitizeSettings(next);
  });

  window.addEventListener("message", (event) => {
    if (
      event.source === window &&
      event.origin === location.origin &&
      event.data?.source === YOUTUBE_METADATA_SOURCE
    ) {
      youtubeMetadata = event.data.payload;
    }
  });

  document.addEventListener("wheel", handleWheel, {
    capture: true,
    passive: false
  });

  loadSettings().catch(() => {
    settings = { ...Core.DEFAULT_SETTINGS };
  });
})();
