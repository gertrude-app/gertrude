import { test, describe, expect } from 'vitest';
import { registrable } from '../domain';

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
    expect(registrable(input)).toMatchObject(expected);
  });
});
