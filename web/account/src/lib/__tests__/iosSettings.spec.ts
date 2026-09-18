import { describe, expect, test } from 'vitest';
import { validateIosSettingsSearch } from '../iosSettings';

describe(`iOS settings navigation`, () => {
  test.each([`blocker`, `podcasts`, `music`] as const)(
    `accepts the %s app section`,
    (section) => {
      expect(validateIosSettingsSearch({ section })).toEqual({ section });
    },
  );

  test.each([undefined, `unknown`, 42])(`rejects the %s app section`, (section) => {
    expect(validateIosSettingsSearch({ section })).toEqual({ section: undefined });
  });
});
