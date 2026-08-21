import { describe, expect, it } from 'vitest';
import { getArticleCTAVariant } from '../articleCTAVariant';

describe(`getArticleCTAVariant()`, () => {
  it.each([`mac`, `blocker`, `music`, `podcasts`] as const)(
    `selects the %s CTA for an article about only that app`,
    (product) => {
      expect(getArticleCTAVariant([product])).toBe(product);
    },
  );

  it(`selects the Explore CTA when no app is associated`, () => {
    expect(getArticleCTAVariant([])).toBe(`explore`);
  });

  it(`selects the Explore CTA when multiple apps are associated`, () => {
    expect(getArticleCTAVariant([`mac`, `blocker`])).toBe(`explore`);
  });
});
