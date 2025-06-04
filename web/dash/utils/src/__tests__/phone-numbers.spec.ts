import { describe, expect, test } from 'vitest';
import { parseE164, prettyE164 } from '../phone-numbers';

describe(`parseE164()`, () => {
  const cases: Array<[string | undefined, string | null]> = [
    [`+1 (555) 555-5555`, `+15555555555`],
    [`+1 (555)     555 (5555)`, `+15555555555`],
    [`(555) 555-5555`, `+15555555555`],
    [`5555555555`, `+15555555555`],
    [`+35555555555`, `+35555555555`],
    [`+35555555555  `, `+35555555555`],
    [`   +35555555555`, `+35555555555`],
    [` \t  +35555555555`, `+35555555555`],
    [`1234567`, `+1234567`], // shortest
    [`123456`, null],
    [`+123456`, null],
    [`123456789012345`, `+123456789012345`], // longest
    [`+123456789012345`, `+123456789012345`],
    [`+123(456)78-9-012345`, `+123456789012345`],
    [`1234567890123456`, null], // too long
    [`+1234567890123456`, null],
    [undefined, null],
  ];
  test.each(cases)(`%s to I.164 -> %s`, (input, expected) => {
    expect(parseE164(input)).toBe(expected);
  });
});

describe(`prettyE164()`, () => {
  const cases: Array<[string, string]> = [
    [`+15555555555`, `(555) 555-5555`],
    [`+1555555555`, `+1555555555`],
    [`+25555555555`, `+25555555555`],
  ];
  test.each(cases)(`%s to pretty -> %s`, (input, expected) => {
    expect(prettyE164(input)).toBe(expected);
  });
});
