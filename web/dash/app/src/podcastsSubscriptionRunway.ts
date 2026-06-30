import { formatDate } from '@dash/datetime';
import type { T } from '@shared/pairql/dashboard';

type PodcastsSubscription = T.ClaimAmDevice.Output[`subscription`];

export type PodcastsRunwayTier = `active` | `expiring` | `lapsed`;

// The effective access *runway*, derived once from the entitlement enum and reused by
// every Podcasts surface (funnel Done screen, iOS-device page section). `active` = paying or a
// trial with comfortable runway (no push); `expiring` = a trial nearing its end, or a
// legacy window the server flags for migration (soft push); `lapsed` = unpaid/expired
// (hard push). Keyed off runway, not raw case names.
const SOFT_PUSH_WINDOW_DAYS = 7;

export interface PodcastsRunway {
  tier: PodcastsRunwayTier;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
  subscribeUrl?: string;
}

export function podcastsSubscriptionRunway(sub: PodcastsSubscription): PodcastsRunway {
  switch (sub.case) {
    case `active`:
    case `complimentary`:
      return { tier: `active` };
    case `amTrial`:
    case `fullTrial`: {
      const days = daysUntil(sub.expiresAt);
      return days <= SOFT_PUSH_WINDOW_DAYS
        ? { tier: `expiring`, accessEndsAt: formatDate(new Date(sub.expiresAt), `long`) }
        : { tier: `active`, trialDaysRemaining: Math.max(days, 0) };
    }
    case `legacyGrandfathered`:
      return sub.showMigrationNag
        ? {
            tier: `expiring`,
            accessEndsAt: formatDate(new Date(sub.accessEndsAt), `long`),
            subscribeUrl: sub.migrationUrl,
          }
        : { tier: `active` };
    case `unpaid`:
      return { tier: `lapsed`, subscribeUrl: sub.remediationUrl };
    case `legacyExpired`:
      return { tier: `lapsed`, subscribeUrl: sub.remediationUrl };
  }
}

function daysUntil(iso: string): number {
  return Math.ceil((new Date(iso).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
}
