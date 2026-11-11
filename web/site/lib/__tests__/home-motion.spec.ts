import { describe, expect, it } from 'vitest';
import { cssTimeToMilliseconds } from '../home-motion';

describe(`CSS animation timing`, () => {
  it.each([
    [`560ms`, 560],
    [`.56s`, 560],
    [`1390ms`, 1390],
    [`1.39s`, 1390],
    [`2400ms`, 2400],
    [`2.4s`, 2400],
    [`3410ms`, 3410],
    [`3.41s`, 3410],
    [`  .56s  `, 560],
    [`0s`, 0],
  ])(`converts %s to %i milliseconds`, (value, milliseconds) => {
    expect(cssTimeToMilliseconds(value)).toBeCloseTo(milliseconds);
  });
});
