import { describe, expect, test } from 'vitest';
import { registrable, removePort, sanitizeUserInput } from '../domain';

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

describe(`removePort()`, () => {
  const cases: [string, string][] = [
    [`example.com`, `example.com`],
    [`example.com:8080`, `example.com`],
    [`192.168.2.1`, `192.168.2.1`],
    [`http://192.168.2.1`, `http://192.168.2.1`],
    [`http://192.168.2.1:8080`, `http://192.168.2.1`],
    [`::1`, `::1`],
    [`192.168.2.1:8080`, `192.168.2.1`],
    [`2607:f8b0:4007:803::200a`, `2607:f8b0:4007:803::200a`],
    [`2607:f8b0:4007:803::2001`, `2607:f8b0:4007:803::2001`],
  ];
  test.each(cases)(`removes port %s -> %s`, (input, expected) => {
    expect(removePort(input)).toBe(expected);
  });
});
