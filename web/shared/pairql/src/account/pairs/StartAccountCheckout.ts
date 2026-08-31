// auto-generated, do not edit
import type { SubscriptionTier } from '../shared';

export namespace StartAccountCheckout {
  export interface Input {
    tier: SubscriptionTier;
    successPath: string;
    cancelPath: string;
  }

  export interface Output {
    url: string;
  }
}
