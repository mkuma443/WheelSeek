(function initializeYouTubeMetadataBridge() {
  "use strict";

  const MESSAGE_SOURCE = "wheelseek-page-metadata";
  const MAX_SCRIPT_SCAN_ATTEMPTS = 6;
  let cachedUrl = "";
  let cachedScriptDetails = null;
  let scriptScanAttempts = 0;

  function unescapeJsonString(value) {
    if (!value) {
      return null;
    }

    try {
      return JSON.parse(`"${value}"`);
    } catch {
      return value;
    }
  }

  function getLiveDetailsFromPageScripts() {
    if (cachedUrl !== location.href) {
      cachedUrl = location.href;
      cachedScriptDetails = null;
      scriptScanAttempts = 0;
    }

    if (cachedScriptDetails) {
      return cachedScriptDetails;
    }

    if (scriptScanAttempts >= MAX_SCRIPT_SCAN_ATTEMPTS) {
      return null;
    }

    scriptScanAttempts += 1;

    for (const script of document.scripts) {
      const text = script.textContent;

      if (
        !text ||
        !text.includes('"liveBroadcastDetails"') ||
        !text.includes('"startTimestamp"')
      ) {
        continue;
      }

      const detailsMatch = text.match(
        /"liveBroadcastDetails":\{([^{}]{1,1000})\}/
      );

      if (!detailsMatch) {
        continue;
      }

      const details = detailsMatch[1];
      const startTimestamp = details.match(/"startTimestamp":"([^"]+)"/)?.[1];

      if (!startTimestamp) {
        continue;
      }

      cachedScriptDetails = {
        isLiveNow: /"isLiveNow":true/.test(details),
        startTimestamp: unescapeJsonString(startTimestamp),
        endTimestamp: unescapeJsonString(
          details.match(/"endTimestamp":"([^"]+)"/)?.[1]
        )
      };
      return cachedScriptDetails;
    }

    return null;
  }

  function getPlayerResponse() {
    const moviePlayer = document.getElementById("movie_player");

    if (moviePlayer && typeof moviePlayer.getPlayerResponse === "function") {
      try {
        return moviePlayer.getPlayerResponse();
      } catch {
        // Fall through to the page-level response.
      }
    }

    return window.ytInitialPlayerResponse || null;
  }

  function publishMetadata() {
    const response = getPlayerResponse();
    const videoDetails = response?.videoDetails || {};
    const renderer = response?.microformat?.playerMicroformatRenderer || {};
    const liveDetails =
      renderer.liveBroadcastDetails || getLiveDetailsFromPageScripts() || {};
    const videoId =
      videoDetails.videoId ||
      new URL(location.href).searchParams.get("v") ||
      null;
    const payload = {
      videoId,
      isLive: videoDetails.isLive === true || liveDetails.isLiveNow === true,
      isLiveContent:
        videoDetails.isLiveContent === true ||
        Boolean(liveDetails.startTimestamp),
      startTimestamp: liveDetails.startTimestamp || null,
      endTimestamp: liveDetails.endTimestamp || null
    };
    window.postMessage(
      {
        source: MESSAGE_SOURCE,
        payload
      },
      window.location.origin
    );
  }

  window.addEventListener("yt-navigate-finish", publishMetadata);
  window.addEventListener("load", publishMetadata, { once: true });
  document.addEventListener("DOMContentLoaded", publishMetadata, { once: true });

  setInterval(publishMetadata, 2000);
})();
