"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const Core = require("../lib/seek-core.js");

test("settings are sanitized and bounded", () => {
  assert.deepEqual(Core.sanitizeSettings({ seekSeconds: 41 }), {
    seekSeconds: 30,
    variableSeekEnabled: false,
    broadcastClockEnabled: false
  });
  assert.equal(Core.sanitizeSettings({ seekSeconds: "7" }).seekSeconds, 7);
  assert.equal(Core.sanitizeSettings({ seekSeconds: "invalid" }).seekSeconds, 10);
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
