import { describe, expect, test } from 'vitest';
import {
  EXTENDED_RESTRICTION_GROUPS,
  SOFTWARE_UPDATE_DELAY_DEFAULT,
  clampSoftwareUpdateDelay,
  controlOffValues,
  controlOnValues,
} from '../supervision';

describe(`software update delay`, () => {
  test(`enabling sets the default duration and disabling clears it`, () => {
    const delay = EXTENDED_RESTRICTION_GROUPS.flatMap((group) => group.controls).find(
      (control) => control.delayDays,
    )!;
    expect(controlOnValues(delay)).toEqual({
      forceDelayedSoftwareUpdates: true,
      enforcedSoftwareUpdateDelay: SOFTWARE_UPDATE_DELAY_DEFAULT,
    });
    expect(controlOffValues(delay)).toEqual({
      forceDelayedSoftwareUpdates: null,
      enforcedSoftwareUpdateDelay: null,
    });
  });

  test(`invalid input uses the default and numeric input stays within the supported range`, () => {
    expect(clampSoftwareUpdateDelay(``)).toBe(30);
    expect(clampSoftwareUpdateDelay(`0`)).toBe(1);
    expect(clampSoftwareUpdateDelay(`45`)).toBe(45);
    expect(clampSoftwareUpdateDelay(`91`)).toBe(90);
  });
});
