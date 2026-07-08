import type { SubscriptionPanelAction, SubscriptionTier } from '@dash/types';

export function planGatePrimaryLabel(action: SubscriptionPanelAction): string {
  switch (action.case) {
    case `openBillingPortal`:
      return `Update payment →`;
    case `startCheckout`:
    case `reactivateViaCheckout`:
      return subscribeLabel(action.tier);
    case `changeSubscriptionTier`:
      return `Upgrade to ${tierName(action.to)}`;
    case `startFullTrial`:
      return `Continue`;
  }
}

function subscribeLabel(tier: SubscriptionTier): string {
  switch (tier) {
    case `light`:
      return `Subscribe — $10/year`;
    case `medium`:
      return `Subscribe — $5/month`;
    case `full`:
      return `Subscribe →`;
  }
}

function tierName(tier: SubscriptionTier): string {
  switch (tier) {
    case `light`:
      return `Light`;
    case `medium`:
      return `Medium`;
    case `full`:
      return `Full`;
  }
}
