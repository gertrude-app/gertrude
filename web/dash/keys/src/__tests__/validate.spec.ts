import { test, describe, expect } from 'vitest';
import type { AddressType } from '../edit';
import * as validate from '../validate';

describe(`validate.address()`, () => {
  const cases: Array<[string, AddressType, boolean]> = [
    [`foo.bar.com`, `standard`, true],
    [`foo.bar.com`, `strict`, true],
    [`foo.bar.com`, `domainRegex`, false],
    [`foobar`, `standard`, false],
    [`foobar`, `strict`, false],
    [`1.2.3.4`, `strict`, false],
    [`1.2.3.4`, `standard`, false],
    [`1.2.3.4`, `domainRegex`, false],
    [`1.2.3.4`, `ip`, true],
    [`foo*.bar.com`, `domainRegex`, true],
  ];

  test.each(cases)(`%s:%s valid=%s`, (address, type, expected) => {
    expect(validate.address(address, type)).toEqual(expected);
  });
});
