import { describe, expect, test } from 'vitest';
import type { T } from '@shared/pairql/dashboard';
import { podcastsDoneVariant } from './podcastsDoneVariant';

type Subscription = T.ClaimAmDevice.Output[`subscription`];

describe(`podcastsDoneVariant()`, () => {
  test(`does not offer light to an active subscriber`, () => {
    const result = podcastsDoneVariant({
      case: `active`,
      expiresAt: `2027-06-13T15:15:52.000Z`,
    });

    expect(result.variant).toBe(`active`);
    expect(result.showSubscribe).toBe(false);
  });

  test(`does not offer light to a complimentary account`, () => {
    const result = podcastsDoneVariant({ case: `complimentary` });

    expect(result.variant).toBe(`active`);
    expect(result.showSubscribe).toBe(false);
  });

  test(`offers light during an active trial`, () => {
    const result = podcastsDoneVariant({
      case: `amTrial`,
      expiresAt: futureDate(30),
    } satisfies Subscription);

    expect(result.variant).toBe(`active`);
    expect(result.showSubscribe).toBe(true);
  });
});

function futureDate(days: number): string {
  return new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();
}
