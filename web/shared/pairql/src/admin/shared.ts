// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

export type ClientAuth = 'none' | 'child' | 'parent' | 'superAdmin';

export type DeviceModelFamily =
  | 'macBook'
  | 'macBookAir'
  | 'macBookPro'
  | 'mini'
  | 'iMac'
  | 'studio'
  | 'pro'
  | 'unknown';

export type GertrudeApp = 'blocker' | 'podcasts';

export type Plan =
  | {
      case: 'free';
      kind:
        | { case: 'lapsedLight'; stripeId: string; hasTrialedFull: boolean }
        | { case: 'lapsedFull'; stripeId?: string }
        | { case: 'standard' };
    }
  | {
      case: 'light';
      status:
        | { case: 'paid'; stripeId: string; hasTrialedFull: boolean }
        | { case: 'overdue'; stripeId: string; hasTrialedFull: boolean };
    }
  | {
      case: 'full';
      status:
        | {
            case: 'trialing';
            kind: { case: 'fromLight'; stripeId: string } | { case: 'full' };
            until: ISODateString;
          }
        | {
            case: 'trialExpired';
            kind: { case: 'fromLight'; stripeId: string } | { case: 'full' };
          }
        | { case: 'paid'; stripeId: string; monthlyPriceInCents: number }
        | { case: 'overdue'; stripeId: string; monthlyPriceInCents: number }
        | { case: 'complimentary' };
    };
