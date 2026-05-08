// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

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

export type Entitlement =
  | { case: 'fullTrial'; until: ISODateString }
  | { case: 'fullTrialGrace'; until: ISODateString }
  | { case: 'free' }
  | { case: 'light' }
  | { case: 'full' }
  | { case: 'complimentary' };

export type GertrudeApp = 'blocker' | 'podcasts';

export type StripeSubscriptionStatus =
  | 'active'
  | 'trialing'
  | 'pastDue'
  | 'unpaid'
  | 'canceled'
  | 'incomplete'
  | 'incompleteExpired';

export type SubscriptionTier = 'light' | 'full';
