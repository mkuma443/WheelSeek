(function initializeWheelSeekTwitchMetadata(root) {
  "use strict";

  const GQL_ENDPOINT = "https://gql.twitch.tv/gql";
  const TWITCH_WEB_CLIENT_ID = "kimne78kx3ncx6brgo4mv6wki5h1ko";
  const VIDEO_METADATA_QUERY =
    "query WheelSeekVideoMetadata($id: ID!) { " +
    "video(id: $id) { id createdAt broadcastType } " +
    "}";

  function extractVideoId(url) {
    try {
      const parsed = new URL(url);
      const match = parsed.pathname.match(/^\/videos\/(\d+)\/?$/);
      return match?.[1] || null;
    } catch {
      return null;
    }
  }

  function parseArchiveMetadata(payload, expectedVideoId) {
    const video = payload?.data?.video;

    if (
      !video ||
      String(video.id) !== String(expectedVideoId) ||
      video.broadcastType !== "ARCHIVE" ||
      !Number.isFinite(Date.parse(video.createdAt))
    ) {
      return null;
    }

    return Object.freeze({
      videoId: String(video.id),
      startTimestamp: video.createdAt
    });
  }

  async function fetchArchiveMetadata(videoId, fetchImplementation = root.fetch) {
    if (!videoId || typeof fetchImplementation !== "function") {
      return null;
    }

    const response = await fetchImplementation(GQL_ENDPOINT, {
      method: "POST",
      credentials: "omit",
      headers: {
        "Client-ID": TWITCH_WEB_CLIENT_ID,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        operationName: "WheelSeekVideoMetadata",
        variables: { id: String(videoId) },
        query: VIDEO_METADATA_QUERY
      })
    });

    if (!response.ok) {
      return null;
    }

    return parseArchiveMetadata(await response.json(), videoId);
  }

  const api = Object.freeze({
    extractVideoId,
    fetchArchiveMetadata,
    parseArchiveMetadata
  });

  root.WheelSeekTwitchMetadata = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof globalThis === "undefined" ? this : globalThis);
