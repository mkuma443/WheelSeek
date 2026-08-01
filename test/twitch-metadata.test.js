"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const TwitchMetadata = require("../lib/twitch-metadata.js");

test("extracts Twitch VOD IDs only from video pages", () => {
  assert.equal(
    TwitchMetadata.extractVideoId("https://www.twitch.tv/videos/2831879920"),
    "2831879920"
  );
  assert.equal(
    TwitchMetadata.extractVideoId("https://www.twitch.tv/videos/2831879920/"),
    "2831879920"
  );
  assert.equal(
    TwitchMetadata.extractVideoId("https://www.twitch.tv/vtuber_noachi"),
    null
  );
});

test("accepts only matching Twitch broadcast archives", () => {
  assert.deepEqual(
    TwitchMetadata.parseArchiveMetadata(
      {
        data: {
          video: {
            id: "2831879920",
            createdAt: "2026-07-29T12:10:34Z",
            broadcastType: "ARCHIVE"
          }
        }
      },
      "2831879920"
    ),
    {
      videoId: "2831879920",
      startTimestamp: "2026-07-29T12:10:34Z"
    }
  );

  assert.equal(
    TwitchMetadata.parseArchiveMetadata(
      {
        data: {
          video: {
            id: "2831879920",
            createdAt: "2026-07-29T12:10:34Z",
            broadcastType: "HIGHLIGHT"
          }
        }
      },
      "2831879920"
    ),
    null
  );
});

test("fetches public archive metadata without credentials", async () => {
  let request = null;
  const result = await TwitchMetadata.fetchArchiveMetadata(
    "2831879920",
    async (url, options) => {
      request = { url, options };
      return {
        ok: true,
        async json() {
          return {
            data: {
              video: {
                id: "2831879920",
                createdAt: "2026-07-29T12:10:34Z",
                broadcastType: "ARCHIVE"
              }
            }
          };
        }
      };
    }
  );

  assert.equal(request.url, "https://gql.twitch.tv/gql");
  assert.equal(request.options.credentials, "omit");
  assert.deepEqual(result, {
    videoId: "2831879920",
    startTimestamp: "2026-07-29T12:10:34Z"
  });
});
