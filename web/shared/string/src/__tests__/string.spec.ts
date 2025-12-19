import { describe, expect, test } from 'vitest';
import { pastTense } from '../';

describe(`pastTense())`, () => {
  const cases = [
    [`accept`, `accepted`],
    [`reject`, `rejected`],
    [`send`, `sent`],
    [`verify`, `verified`],
    [`delete`, `deleted`],
    [`update`, `updated`],
    [`create`, `created`],
    [`save`, `saved`],
  ];

  test.each(cases)(`pastTense(%s) -> %s`, (input, expected) => {
    expect(pastTense(input)).toBe(expected);
  });
});
