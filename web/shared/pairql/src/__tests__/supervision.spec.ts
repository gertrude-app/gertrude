import { describe, expect, test } from 'vitest';
import {
  EMPTY_EXTENDED,
  EXTENDED_RESTRICTION_GROUPS,
  SOFTWARE_UPDATE_DELAY_DEFAULT,
  clampSoftwareUpdateDelay,
  controlOffValues,
  controlOnValues,
  extendedControlsPayload,
  groupValues,
  isControlOn,
  normalizeExtended,
} from '../supervision';

const controls = EXTENDED_RESTRICTION_GROUPS.flatMap((group) => group.controls);

describe(`supervision restriction values`, () => {
  test.each(controls)(
    `$field toggles between the restrictive value and no override`,
    (control) => {
      const on = { ...EMPTY_EXTENDED, ...controlOnValues(control) };
      expect(isControlOn(on, control)).toBe(true);
      expect(extendedControlsPayload(on)[control.field]).toBe(control.restrictValue);
      expect(isControlOn({ ...on, ...controlOffValues(control) }, control)).toBe(false);
      expect(extendedControlsPayload({ ...on, ...controlOffValues(control) })).toEqual(
        {},
      );
    },
  );

  test.each(EXTENDED_RESTRICTION_GROUPS)(
    `$id group toggles all its restrictions`,
    (group) => {
      const on = { ...EMPTY_EXTENDED, ...groupValues(group, true) };
      expect(group.controls.every((control) => isControlOn(on, control))).toBe(true);
      const off = { ...on, ...groupValues(group, false) };
      expect(extendedControlsPayload(off)).toEqual({});
    },
  );

  test(`non-null overrides use the legacy enabled-state behavior`, () => {
    const safari = controls.find((control) => control.field === `allowSafari`)!;
    expect(isControlOn(normalizeExtended({ allowSafari: true }), safari)).toBe(true);
    expect(isControlOn(normalizeExtended({ allowSafari: false }), safari)).toBe(true);
    expect(isControlOn(normalizeExtended(undefined), safari)).toBe(false);
  });

  test(`normalization and payload round trip preserve false and zero`, () => {
    const payload = {
      allowSafari: false,
      ratingMovies: 0,
      forceAutomaticDateAndTime: true,
    };
    expect(extendedControlsPayload(normalizeExtended(payload))).toEqual(payload);
    expect(extendedControlsPayload(normalizeExtended(undefined))).toEqual({});
  });

  test(`disabling delayed updates also clears the day count`, () => {
    const delay = controls.find((control) => control.delayDays)!;
    expect(controlOnValues(delay).enforcedSoftwareUpdateDelay).toBe(
      SOFTWARE_UPDATE_DELAY_DEFAULT,
    );
    expect(controlOffValues(delay).enforcedSoftwareUpdateDelay).toBeNull();
  });

  test.each([
    [``, 30],
    [`not a number`, 30],
    [`0`, 1],
    [`-5`, 1],
    [`45`, 45],
    [`91`, 90],
  ])(`delay %s is clamped to %s days`, (raw, expected) => {
    expect(clampSoftwareUpdateDelay(String(raw))).toBe(expected);
  });
});
