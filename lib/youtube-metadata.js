(function initializeWheelSeekYouTubeMetadata(root, factory) {
  const api = factory();

  if (typeof module === "object" && module.exports) {
    module.exports = api;
  }

  root.WheelSeekYouTubeMetadata = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function createApi() {
  "use strict";

  function getVideoIdFromUrl(value) {
    try {
      const url = new URL(value);

      if (url.pathname === "/watch") {
        return url.searchParams.get("v") || null;
      }

      const liveMatch = url.pathname.match(/^\/live\/([^/?#]+)/);
      return liveMatch ? decodeURIComponent(liveMatch[1]) : null;
    } catch {
      return null;
    }
  }

  function emptyPayload(videoId = null) {
    return {
      videoId,
      isLive: false,
      isLiveContent: false,
      startTimestamp: null,
      endTimestamp: null
    };
  }

  function buildPayload(response, locationHref) {
    const locationVideoId = getVideoIdFromUrl(locationHref);
    const videoDetails = response?.videoDetails || {};
    const responseVideoId = videoDetails.videoId || null;
    const videoId = locationVideoId || responseVideoId;

    if (!responseVideoId || (locationVideoId && responseVideoId !== locationVideoId)) {
      return emptyPayload(videoId);
    }

    const renderer = response?.microformat?.playerMicroformatRenderer || {};
    const liveDetails = renderer.liveBroadcastDetails || {};
    const startTimestamp = liveDetails.startTimestamp || null;
    const isLiveContent =
      videoDetails.isLiveContent === true || Boolean(startTimestamp);

    if (!isLiveContent) {
      return emptyPayload(videoId);
    }

    return {
      videoId,
      isLive: videoDetails.isLive === true || liveDetails.isLiveNow === true,
      isLiveContent: true,
      startTimestamp,
      endTimestamp: liveDetails.endTimestamp || null
    };
  }

  function metadataMatchesUrl(metadata, locationHref) {
    const locationVideoId = getVideoIdFromUrl(locationHref);
    return Boolean(
      metadata &&
        locationVideoId &&
        metadata.videoId === locationVideoId
    );
  }

  return {
    buildPayload,
    getVideoIdFromUrl,
    metadataMatchesUrl
  };
});
