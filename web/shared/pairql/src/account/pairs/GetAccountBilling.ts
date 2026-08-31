// auto-generated, do not edit
import type { PlanStatus, SubscriptionPanelAction, SubscriptionTier } from '../shared';

export namespace GetAccountBilling {
  export type Input = void;

  export interface Output {
    planStatus: PlanStatus;
    primary?: SubscriptionPanelAction;
    secondary: SubscriptionPanelAction[];
    availableTiers: SubscriptionTier[];
    fullTrialStartedAt?: ISODateString;
    lastPaidTier?: SubscriptionTier;
  }
}
