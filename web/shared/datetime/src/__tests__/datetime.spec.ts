import { describe, expect, test } from 'vitest';
import { time } from '../';

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
