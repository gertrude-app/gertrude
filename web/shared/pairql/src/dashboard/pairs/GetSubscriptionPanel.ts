// auto-generated, do not edit
import type { Entitlement, SubscriptionPanelAction, SubscriptionTier } from '../shared';

export namespace GetSubscriptionPanel {
  export type Input = void;

  export interface Output {
    entitlement: Entitlement;
    billing: {
      status?: 'active' | 'pastDue';
      currentPeriodEnd?: ISODateString;
    };
    primary?: SubscriptionPanelAction;
    secondary: SubscriptionPanelAction[];
    availableTiers: SubscriptionTier[];
  }
}
