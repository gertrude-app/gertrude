// auto-generated, do not edit
import type { SubscriptionTier } from '../shared';

export namespace StartCheckoutSession {
  export interface Input {
    tier: SubscriptionTier;
    successPath: string;
    cancelPath: string;
    associatedIosDeviceId?: UUID;
  }

  export interface Output {
    url: string;
  }
}
