import type { PodcastsRunwayTier } from '../../../podcastsSubscriptionRunway';
import type { PodcastsDoneVariant } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import { podcastsSubscriptionRunway } from '../../../podcastsSubscriptionRunway';

export interface PodcastsDonePresentation {
  variant: PodcastsDoneVariant;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
  subscribeUrl?: string;
  showSubscribe: boolean;
}

const TIER_TO_VARIANT: Record<PodcastsRunwayTier, PodcastsDoneVariant> = {
  active: `active`,
  expiring: `approachingExpiry`,
  lapsed: `notEntitled`,
};

export function podcastsDoneVariant(
  sub: T.ClaimAmDevice.Output[`subscription`],
): PodcastsDonePresentation {
  const runway = podcastsSubscriptionRunway(sub);
  return {
    variant: TIER_TO_VARIANT[runway.tier],
    accessEndsAt: runway.accessEndsAt,
    trialDaysRemaining: runway.trialDaysRemaining,
    subscribeUrl: runway.subscribeUrl,
    showSubscribe:
      runway.tier !== `active` || sub.case === `amTrial` || sub.case === `fullTrial`,
  };
}
