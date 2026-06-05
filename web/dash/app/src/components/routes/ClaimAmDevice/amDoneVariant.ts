import type { AmRunwayTier } from '../../../amSubscriptionRunway';
import type { AmDoneVariant } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import { amSubscriptionRunway } from '../../../amSubscriptionRunway';

export interface AmDonePresentation {
  variant: AmDoneVariant;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
  subscribeUrl?: string;
}

const TIER_TO_VARIANT: Record<AmRunwayTier, AmDoneVariant> = {
  active: `active`,
  expiring: `approachingExpiry`,
  lapsed: `notEntitled`,
};

export function amDoneVariant(
  sub: T.ClaimAmDevice.Output[`subscription`],
): AmDonePresentation {
  const runway = amSubscriptionRunway(sub);
  return {
    variant: TIER_TO_VARIANT[runway.tier],
    accessEndsAt: runway.accessEndsAt,
    trialDaysRemaining: runway.trialDaysRemaining,
    subscribeUrl: runway.subscribeUrl,
  };
}
