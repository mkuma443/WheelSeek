(function initializeYouTubeMetadataBridge() {
  "use strict";

  const MESSAGE_SOURCE = "wheelseek-page-metadata";
  const Metadata = globalThis.WheelSeekYouTubeMetadata;

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
    const payload = Metadata.buildPayload(response, location.href);
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
