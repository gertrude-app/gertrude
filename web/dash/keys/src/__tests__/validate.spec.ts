import { describe, expect, test } from 'vitest';
import type { AddressType } from '../edit';
import * as validate from '../validate';

describe(`validate.address()`, () => {
  const cases: Array<[string, AddressType, boolean]> = [
    [`foo.bar.com`, `standard`, true],
    [`foo.bar.com`, `strict`, true],
    [`foobar`, `standard`, false],
    [`foobar`, `strict`, false],
    [`1.2.3.4`, `strict`, false],
    [`1.2.3.4`, `standard`, false],
    [`1.2.3.4`, `ip`, true],
    [`^.*\\.edu$`, `domainRegex`, true],
    [`^(harvard|mit)\\.edu$`, `domainRegex`, true],
    [`*.foo.com`, `domainRegex`, false],
    [`.*`, `domainRegex`, false],
  ];

  test.each(cases)(`%s:%s valid=%s`, (address, type, expected) => {
    expect(validate.address(address, type)).toEqual(expected);
  });
});

describe(`validate.domainRegex()`, () => {
  test(`accepts a real-regex pattern`, () => {
    expect(validate.domainRegex(`^.*\\.edu$`)).toBeNull();
    expect(validate.domainRegex(`^(harvard|mit|stanford)\\.edu$`)).toBeNull();
    expect(validate.domainRegex(`^[a-z]+\\.gov$`)).toBeNull();
    expect(validate.domainRegex(`^MIT\\.EDU$`)).toBeNull();
  });

  test(`rejects pattern that fails to compile`, () => {
    const err = validate.domainRegex(`*.foo.com`);
    expect(err).toMatch(/^invalid regex pattern:/);
  });

  test(`rejects pattern that exceeds the length cap`, () => {
    const long = `a`.repeat(201);
    expect(validate.domainRegex(long)).toBe(`regex pattern too long: 201 chars, max 200`);
  });

  test(`rejects pattern that matches the empty string`, () => {
    expect(validate.domainRegex(`.*`)).toBe(
      `regex pattern is too broad: matches the empty string`,
    );
    expect(validate.domainRegex(`^$`)).toBe(
      `regex pattern is too broad: matches the empty string`,
    );
    expect(validate.domainRegex(`a?`)).toBe(
      `regex pattern is too broad: matches the empty string`,
    );
  });

  test(`rejects pattern that matches an arbitrary hostname canary`, () => {
    expect(validate.domainRegex(`.+\\.invalid`)).toBe(
      `regex pattern is too broad: matches arbitrary hostnames`,
    );
  });

  test(`rejects pattern with no literal alphanumeric content`, () => {
    expect(validate.domainRegex(`\\d+\\.\\d+`)).toBe(
      `regex pattern must contain at least one literal alphanumeric character`,
    );
  });

  test(`accepts pattern whose only literal content is inside the regex`, () => {
    expect(validate.domainRegex(`mit\\.edu`)).toBeNull();
  });

  test(`treats character class bodies as non-literal`, () => {
    expect(validate.domainRegex(`[0-9]+`)).toBe(
      `regex pattern must contain at least one literal alphanumeric character`,
    );
  });
});
