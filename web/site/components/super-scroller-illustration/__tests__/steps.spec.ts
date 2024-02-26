import { describe, it, expect } from 'vitest';
import { compareTo, parseStep } from '../utils';

describe(`parseStep()`, () => {
  it(`returns the step and subStep`, () => {
    expect(parseStep(`1-0_start`)).toEqual([1, 0]);
    expect(parseStep(`1-1_openLoginScreen`)).toEqual([1, 1]);
    expect(parseStep(`3-0_start`)).toEqual([3, 0]);
    expect(parseStep(`4-1_clickUnlockRequest`)).toEqual([4, 1]);
    expect(parseStep(`5-2_clickAcceptRequest`)).toEqual([5, 2]);
    expect(parseStep(`6-0_start`)).toEqual([6, 0]);
  });
});

describe(`compareTo()`, () => {
  it(`returns true if the step is before the comparison`, () => {
    const hasHappened = compareTo(`2-1_openMac`);
    expect(hasHappened(`1-0_start`)).toBe(true);
    expect(hasHappened(`1-1_openLoginScreen`)).toBe(true);
    expect(hasHappened(`1-2_logIn`)).toBe(true);
    expect(hasHappened(`2-0_start`)).toBe(true);
    expect(hasHappened(`2-1_openMac`)).toBe(true);
    expect(hasHappened(`2-2_clickDownloadButton`)).toBe(false);
    expect(hasHappened(`3-0_start`)).toBe(false);
  });
});
