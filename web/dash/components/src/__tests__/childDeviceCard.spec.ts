import { afterEach, describe, expect, test, vi } from 'vitest';
import type { ChildComputerStatus } from '@dash/types';
import { macStatusInfo } from '../Dashboard/ChildDeviceCard';

afterEach(() => vi.useRealTimers());

describe(`macStatusInfo()`, () => {
  test.each<[ChildComputerStatus, string]>([
    [
      { case: `filterSuspended`, resuming: `2026-08-19T12:10:00Z` },
      `Suspended · resumes in 10 minutes`,
    ],
    [
      { case: `downtime`, ending: `2026-08-19T12:10:00Z` },
      `Downtime · ends in 10 minutes`,
    ],
    [
      { case: `downtimePaused`, resuming: `2026-08-19T12:10:00Z` },
      `Paused · resumes in 10 minutes`,
    ],
  ])(`includes timing for %s`, (status, expected) => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(`2026-08-19T12:00:00Z`));

    expect(macStatusInfo(status).text).toBe(expected);
  });

  test.each<[ChildComputerStatus, string]>([
    [{ case: `filterSuspended` }, `Suspended`],
    [{ case: `downtime` }, `Downtime`],
    [{ case: `downtimePaused` }, `Paused`],
  ])(`retains the short label without timing for %s`, (status, expected) => {
    expect(macStatusInfo(status).text).toBe(expected);
  });
});
