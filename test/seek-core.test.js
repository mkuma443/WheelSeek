"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const Core = require("../lib/seek-core.js");

test("settings are sanitized and bounded", () => {
  assert.deepEqual(Core.sanitizeSettings({ seekSeconds: 41 }), {
    seekSeconds: 30,
    variableSeekEnabled: true,
    broadcastClockEnabled: true
  });
  assert.equal(Core.sanitizeSettings({ seekSeconds: "7" }).seekSeconds, 7);
  assert.equal(Core.sanitizeSettings({ seekSeconds: "invalid" }).seekSeconds, 10);
  assert.deepEqual(
    Core.sanitizeSettings({
      variableSeekEnabled: false,
      broadcastClockEnabled: false
    }),
    {
      seekSeconds: 10,
      variableSeekEnabled: false,
      broadcastClockEnabled: false
    }
  );
});

test("wheel deltas are normalized from pixels, lines, and pages", () => {
  assert.equal(Core.normalizeWheelDelta({ deltaY: 100, deltaMode: 0 }), 100);
  assert.equal(Core.normalizeWheelDelta({ deltaY: 3, deltaMode: 1 }), 48);
  assert.equal(Core.normalizeWheelDelta({ deltaY: 1, deltaMode: 2 }, 900), 900);
});

test("variable seek maps recent wheel intensity from 5 to 60 seconds", () => {
  assert.equal(Core.variableSeekSeconds(20), 5);
  assert.equal(Core.variableSeekSeconds(101), 10);
  assert.equal(Core.variableSeekSeconds(499), 25);
  assert.equal(Core.variableSeekSeconds(900), 45);
  assert.equal(Core.variableSeekSeconds(1200), 60);
  assert.equal(Core.variableSeekSeconds(1800), 60);
});

test("Shift seek overrides fixed and variable preferences", () => {
  assert.equal(
    Core.seekSecondsForInput(
      { seekSeconds: 7, variableSeekEnabled: true },
      true,
      10
    ),
    30
  );
});

test("seek targets are clamped to the seekable range", () => {
  const bounds = { start: 10, end: 100 };

  assert.equal(Core.resolveSeekTarget(50, 10, bounds), 60);
  assert.equal(Core.resolveSeekTarget(95, 30, bounds), 100);
  assert.equal(Core.resolveSeekTarget(15, -30, bounds), 10);
});

test("Twitch-style open-ended live ranges are detected", () => {
  assert.equal(
    Core.isOpenEndedLiveRange(Infinity, {
      start: 0,
      end: 1073741824,
      span: 1073741824
    }),
    true
  );
  assert.equal(
    Core.isOpenEndedLiveRange(10082, {
      start: 0,
      end: 10082,
      span: 10082
    }),
    false
  );
});

test("archive clock adds playback time to the actual start", () => {
  assert.equal(
    Core.archiveClockDate("2026-07-26T10:00:00.000Z", 32 * 60).toISOString(),
    "2026-07-26T10:32:00.000Z"
  );
});

test("live clock subtracts distance from the live edge", () => {
  const now = Date.parse("2026-07-26T11:00:00.000Z");

  assert.equal(
    Core.liveClockDate(now, 940, 1000).toISOString(),
    "2026-07-26T10:59:00.000Z"
  );
});

test("YouTube live clock prefers the actual start timestamp over DVR end", () => {
  const date = Core.broadcastClockDate(
    "2026-07-27T02:29:50.000Z",
    Date.parse("2026-07-27T04:20:56.000Z"),
    6663.762,
    10208
  );

  assert.equal(date.toISOString(), "2026-07-27T04:20:53.762Z");
});
