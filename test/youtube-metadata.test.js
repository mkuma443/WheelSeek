"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const Metadata = require("../lib/youtube-metadata.js");

function playerResponse(videoId, overrides = {}) {
  return {
    videoDetails: {
      videoId,
      isLive: false,
      isLiveContent: false,
      ...overrides.videoDetails
    },
    microformat: {
      playerMicroformatRenderer: {
        ...overrides.renderer
      }
    }
  };
}

test("extracts video IDs from YouTube watch and live URLs", () => {
  assert.equal(
    Metadata.getVideoIdFromUrl("https://www.youtube.com/watch?v=current123"),
    "current123"
  );
  assert.equal(
    Metadata.getVideoIdFromUrl("https://www.youtube.com/live/current456"),
    "current456"
  );
});

test("accepts live metadata for the video currently in the URL", () => {
  const response = playerResponse("live123", {
    videoDetails: { isLiveContent: true },
    renderer: {
      liveBroadcastDetails: {
        startTimestamp: "2026-07-26T10:00:00Z",
        endTimestamp: "2026-07-26T12:00:00Z"
      }
    }
  });

  assert.deepEqual(
    Metadata.buildPayload(
      response,
      "https://www.youtube.com/watch?v=live123"
    ),
    {
      videoId: "live123",
      isLive: false,
      isLiveContent: true,
      startTimestamp: "2026-07-26T10:00:00Z",
      endTimestamp: "2026-07-26T12:00:00Z"
    }
  );
});

test("rejects stale live metadata after YouTube navigation", () => {
  const staleResponse = playerResponse("previousLive", {
    videoDetails: { isLiveContent: true },
    renderer: {
      liveBroadcastDetails: {
        startTimestamp: "2026-07-26T10:00:00Z"
      }
    }
  });

  assert.deepEqual(
    Metadata.buildPayload(
      staleResponse,
      "https://www.youtube.com/watch?v=currentClip"
    ),
    {
      videoId: "currentClip",
      isLive: false,
      isLiveContent: false,
      startTimestamp: null,
      endTimestamp: null
    }
  );
});

test("does not classify an ordinary uploaded clip as live content", () => {
  const response = playerResponse("currentClip");

  assert.deepEqual(
    Metadata.buildPayload(
      response,
      "https://www.youtube.com/watch?v=currentClip"
    ),
    {
      videoId: "currentClip",
      isLive: false,
      isLiveContent: false,
      startTimestamp: null,
      endTimestamp: null
    }
  );
});

test("matches cached metadata only to the current YouTube video", () => {
  const metadata = { videoId: "live123" };

  assert.equal(
    Metadata.metadataMatchesUrl(
      metadata,
      "https://www.youtube.com/watch?v=live123"
    ),
    true
  );
  assert.equal(
    Metadata.metadataMatchesUrl(
      metadata,
      "https://www.youtube.com/watch?v=clip456"
    ),
    false
  );
});
