import { formatDate } from '@shared/datetime';
import type { IosPodcastsSubscription } from '#/components/pages/person-settings/IosSettingsPage.types';

export type PodcastsRunwayTier = `active` | `expiring` | `lapsed`;

// Ported from dash's `podcastsSubscriptionRunway`, minus `subscribeUrl` — the account
// site has no billing surface to send anyone to yet. `active` = paying or a trial with
// comfortable runway (no push); `expiring` = a trial nearing its end, or a legacy window
// the server flags for migration (soft push); `lapsed` = unpaid/expired (hard push).
const SOFT_PUSH_WINDOW_DAYS = 7;

export interface PodcastsRunway {
  tier: PodcastsRunwayTier;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
}

export function podcastsSubscriptionRunway(sub: IosPodcastsSubscription): PodcastsRunway {
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
          }
        : { tier: `active` };
    case `unpaid`:
    case `legacyExpired`:
      return { tier: `lapsed` };
  }
}

function daysUntil(iso: string): number {
  return Math.ceil((new Date(iso).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
}
