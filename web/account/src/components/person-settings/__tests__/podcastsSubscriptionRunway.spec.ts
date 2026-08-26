import { describe, expect, test } from 'vitest';
import type { IosPodcastsSubscription } from '#/components/pages/person-settings/IosSettingsPage.types';
import type { PodcastsRunwayTier } from '../podcastsSubscriptionRunway';
import { podcastsSubscriptionRunway as runway } from '../podcastsSubscriptionRunway';

const daysFromNow = (days: number): string =>
  new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();

describe(`podcastsSubscriptionRunway()`, () => {
  test(`the 7-day window decides both tier and which fields are populated`, () => {
    const comfortable = runway({ case: `amTrial`, expiresAt: daysFromNow(21) });
    expect(comfortable.tier).toBe(`active`);
    expect(comfortable.trialDaysRemaining).toBe(21);
    expect(comfortable.accessEndsAt).toBeUndefined(); // no date until it's close

    const closing = runway({ case: `fullTrial`, expiresAt: daysFromNow(3) });
    expect(closing.tier).toBe(`expiring`);
    expect(closing.accessEndsAt).toBeTypeOf(`string`);
    expect(closing.trialDaysRemaining).toBeUndefined(); // the date replaces the countdown
  });

  test(`legacy grandfathering follows the server's nag decision`, () => {
    const base = { case: `legacyGrandfathered`, accessEndsAt: daysFromNow(40) } as const;
    // server decides, so a far-off end date still nags when it says to
    expect(runway({ ...base, showMigrationNag: true }).tier).toBe(`expiring`);
    expect(runway({ ...base, showMigrationNag: false }).tier).toBe(`active`);
  });

  test(`cases with no runway to compute map straight to a tier`, () => {
    const mappings: Array<[IosPodcastsSubscription, PodcastsRunwayTier]> = [
      [{ case: `active`, expiresAt: daysFromNow(300) }, `active`],
      [{ case: `complimentary` }, `active`],
      [{ case: `unpaid` }, `lapsed`],
      [{ case: `legacyExpired`, paidAt: daysFromNow(-400) }, `lapsed`],
    ];
    for (const [sub, tier] of mappings) {
      expect(runway(sub)).toEqual({ tier }); // exactly `{ tier }` — no stray fields
    }
  });
});
