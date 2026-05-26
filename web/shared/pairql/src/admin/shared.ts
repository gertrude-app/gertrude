// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

export type BillingStatus =
  | { case: 'current'; renewsAt: ISODateString }
  | { case: 'pastDue'; since: ISODateString };

export type ClientAuth = 'none' | 'child' | 'parent' | 'superAdmin';

export type DeviceModelFamily =
  | 'macBook'
  | 'macBookAir'
  | 'macBookNeo'
  | 'macBookPro'
  | 'mini'
  | 'iMac'
  | 'studio'
  | 'pro'
  | 'unknown';

export type GertrudeApp = 'blocker' | 'podcasts';

export interface PaidSubscription {
  tier: 'light' | 'full';
  status:
    | { case: 'current'; renewsAt: ISODateString }
    | { case: 'pastDue'; since: ISODateString };
}

export type PlanStatus =
  | {
      case: 'light';
      status:
        | { case: 'current'; renewsAt: ISODateString }
        | { case: 'pastDue'; since: ISODateString };
    }
  | {
      case: 'full';
      status:
        | { case: 'current'; renewsAt: ISODateString }
        | { case: 'pastDue'; since: ISODateString };
    }
  | { case: 'fullTrial'; until: ISODateString; substrate?: PaidSubscription }
  | { case: 'fullTrialGrace'; until: ISODateString; substrate?: PaidSubscription }
  | { case: 'free' }
  | { case: 'complimentary' };

export type StripeSubscriptionStatus =
  | 'active'
  | 'trialing'
  | 'pastDue'
  | 'unpaid'
  | 'canceled'
  | 'incomplete'
  | 'incompleteExpired';

export type SubscriptionTier = 'light' | 'full';
