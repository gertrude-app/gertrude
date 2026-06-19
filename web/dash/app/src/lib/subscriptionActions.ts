import type { SubscriptionPanelAction } from '@dash/types';

export function lightPlanGatePrimaryLabel(action: SubscriptionPanelAction): string {
  switch (action.case) {
    case `openBillingPortal`:
      return `Update payment →`;
    case `startCheckout`:
    case `reactivateViaCheckout`:
      return action.tier === `light` ? `Subscribe — $10/year` : `Subscribe →`;
    case `changeSubscriptionTier`:
    case `startFullTrial`:
      return `Continue`;
  }
}
