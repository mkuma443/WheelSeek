(function initializeWheelSeekCore(root) {
  "use strict";

  const DEFAULT_SETTINGS = Object.freeze({
    seekSeconds: 10,
    variableSeekEnabled: true,
    broadcastClockEnabled: true
  });

  function clamp(value, minimum, maximum) {
    return Math.min(Math.max(value, minimum), maximum);
  }

  function sanitizeSettings(value = {}) {
    const seconds = Number(value.seekSeconds);

    return {
      seekSeconds: Number.isFinite(seconds)
        ? Math.round(clamp(seconds, 5, 30))
        : DEFAULT_SETTINGS.seekSeconds,
      variableSeekEnabled:
        typeof value.variableSeekEnabled === "boolean"
          ? value.variableSeekEnabled
          : DEFAULT_SETTINGS.variableSeekEnabled,
      broadcastClockEnabled:
        typeof value.broadcastClockEnabled === "boolean"
          ? value.broadcastClockEnabled
          : DEFAULT_SETTINGS.broadcastClockEnabled
    };
  }

  function normalizeWheelDelta(event, viewportHeight = 800) {
    const raw = Number(event.deltaY) || 0;

    if (event.deltaMode === 1) {
      return raw * 16;
    }

    if (event.deltaMode === 2) {
      return raw * viewportHeight;
    }

    return raw;
  }

  function variableSeekSeconds(recentAbsoluteDelta) {
    const notchCount = Math.max(1, Math.ceil(recentAbsoluteDelta / 100));
    return clamp(notchCount * 5, 5, 60);
  }

  function seekSecondsForInput(settings, shiftKey, recentAbsoluteDelta) {
    if (shiftKey) {
      return 30;
    }

    if (settings.variableSeekEnabled) {
      return variableSeekSeconds(recentAbsoluteDelta);
    }

    return settings.seekSeconds;
  }

  function getSeekBounds(video) {
    if (!video || !video.seekable || video.seekable.length === 0) {
      return null;
    }

    try {
      const first = video.seekable.start(0);
      const last = video.seekable.end(video.seekable.length - 1);

      if (!Number.isFinite(first) || !Number.isFinite(last) || last <= first) {
        return null;
      }

      return { start: first, end: last, span: last - first };
    } catch {
      return null;
    }
  }

  function resolveSeekTarget(currentTime, deltaSeconds, bounds) {
    if (!bounds) {
      return null;
    }

    return clamp(currentTime + deltaSeconds, bounds.start, bounds.end);
  }

  function isOpenEndedLiveRange(
    duration,
    bounds,
    endThreshold = 1_000_000_000
  ) {
    if (!bounds || !Number.isFinite(bounds.end)) {
      return false;
    }

    return (
      !Number.isFinite(duration) ||
      duration === Infinity ||
      bounds.end >= endThreshold
    );
  }

  function archiveClockDate(startTimestamp, playbackSeconds) {
    const start = Date.parse(startTimestamp);

    if (!Number.isFinite(start) || !Number.isFinite(playbackSeconds)) {
      return null;
    }

    return new Date(start + Math.max(0, playbackSeconds) * 1000);
  }

  function liveClockDate(nowMilliseconds, currentTime, seekableEnd) {
    if (
      !Number.isFinite(nowMilliseconds) ||
      !Number.isFinite(currentTime) ||
      !Number.isFinite(seekableEnd)
    ) {
      return null;
    }

    const secondsBehindLiveEdge = Math.max(0, seekableEnd - currentTime);
    return new Date(nowMilliseconds - secondsBehindLiveEdge * 1000);
  }

  function broadcastClockDate(
    startTimestamp,
    nowMilliseconds,
    currentTime,
    seekableEnd
  ) {
    if (startTimestamp) {
      const archiveDate = archiveClockDate(startTimestamp, currentTime);

      if (archiveDate) {
        return archiveDate;
      }
    }

    return liveClockDate(nowMilliseconds, currentTime, seekableEnd);
  }

  function formatLocalDateTime(date, locale) {
    if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
      return null;
    }

    const parts = new Intl.DateTimeFormat(locale || undefined, {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: false,
      hourCycle: "h23"
    }).formatToParts(date);
    const value = Object.fromEntries(
      parts.filter((part) => part.type !== "literal").map((part) => [part.type, part.value])
    );

    return `${value.year}/${value.month}/${value.day} ${value.hour}:${value.minute}:${value.second}`;
  }

  const api = Object.freeze({
    DEFAULT_SETTINGS,
    archiveClockDate,
    broadcastClockDate,
    clamp,
    formatLocalDateTime,
    getSeekBounds,
    isOpenEndedLiveRange,
    liveClockDate,
    normalizeWheelDelta,
    resolveSeekTarget,
    sanitizeSettings,
    seekSecondsForInput,
    variableSeekSeconds
  });

  root.WheelSeekCore = api;

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  }
})(typeof globalThis === "undefined" ? this : globalThis);
