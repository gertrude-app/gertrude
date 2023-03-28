import { test, describe, expect } from 'vitest';
import { registrable, sanitizeUserInput } from '../domain';

describe(`registrable()`, () => {
  const cases: [string, string][] = [
    [`example.com`, `example.com`],
    [`EXAMPLE.com`, `example.com`],
    [`www.example.com`, `example.com`],
    [`docs.example.com`, `example.com`],
    [`lol.spendable.io`, `spendable.io`],
    [`docs.what.weird.example.com`, `example.com`],
    [`www.example.co.uk`, `example.co.uk`],
    [`www.example.co.uk:8080`, `example.co.uk`],
  ];
  test.each(cases)(`extract registrable domain %s -> %s`, (input, expected) => {
    expect(registrable(input)).toBe(expected);
  });
});

describe(`sanitizeUserInput()`, () => {
  const cases: [string, string][] = [
    [`https://example.com`, `example.com`],
    [`http://example.com`, `example.com`],
    [`http://eXamPle.Com`, `example.com`],
    [`example.com/foo/bar`, `example.com`],
    [`https://example.com/foo/bar`, `example.com`],
    [`example.com/foo?lol=rofl`, `example.com`],
  ];
  test.each(cases)(`sanitize user input %s -> %s`, (input, expected) => {
    expect(sanitizeUserInput(input)).toBe(expected);
  });
});
