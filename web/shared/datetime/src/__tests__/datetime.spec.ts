import { afterEach, describe, expect, test, vi } from 'vitest';
import { formatTime, relativeTime, time } from '../';

afterEach(() => vi.useRealTimers());

describe(`formatTime`, () => {
  test(`formats a local time without seconds`, () => {
    expect(formatTime(new Date(2026, 6, 3, 9, 5))).toBe(`9:05 AM`);
  });
});

describe(`relativeTime`, () => {
  test(`formats a past date relative to now`, () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(`2026-07-27T12:00:00Z`));

    expect(relativeTime(`2026-07-27T11:56:00Z`)).toBe(`4 minutes ago`);
  });
});

describe(`time.humanDuration`, () => {
  const cases: Array<[number, string]> = [
    [0, `0 minutes`],
    [60, `1 minute`],
    [5 * 60, `5 minutes`],
    [5 * 60 + 29, `5 minutes`],
    [5 * 60 + 30, `6 minutes`],
    [5 * 60 + 31, `6 minutes`],
    [60 * 60, `1 hour`],
    [60 * 60 + 1, `1 hour`],
    [90 * 60, `90 minutes`],
    [80 * 60, `1 hour 20 minutes`],
    [120 * 60, `2 hours`],
    [150 * 60, `2.5 hours`],
    [155 * 60, `2 hours 35 minutes`],
  ];
  test.each(cases)(`%s seconds converts to "%s"`, (input, expected) => {
    expect(time.humanDuration(input)).toBe(expected);
  });
});
