import { formatDate } from '@shared/datetime';
import type {
  GetSubscriptionPanel_v2,
  SubscriptionPanelAction,
  SubscriptionTier,
} from '@dash/types';
import type { BadgeType } from '@shared/components';

export type Input = GetSubscriptionPanel_v2.Output;

export interface BadgeOutput {
  text: string;
  type: BadgeType;
}

const EXPIRING_SOON_THRESHOLD_MS = 3 * 24 * 60 * 60 * 1000;

export function title(input: Input): string {
  switch (input.planStatus.case) {
    case `free`:
      return `Free plan`;
    case `light`:
      return `Light plan`;
    case `full`:
    case `complimentary`:
      return `Full plan`;
    case `fullTrial`:
    case `fullTrialGrace`:
      return `Full trial`;
  }
}

export function subtext(input: Input): string {
  const { planStatus } = input;
  switch (planStatus.case) {
    case `free`:
      return `Protect child iPhones and iPads with the Gertrude iOS app.`;
    case `light`:
      return `$10/year. Protect child and adult (supervised) iPhones and iPads with the Gertrude iOS app.`;
    case `full`:
    case `complimentary`:
      return `$10/month. Protect and monitor Macs, iPhones and iPads for the whole family.`;
    case `fullTrial`:
      return `Your free trial ends ${long(planStatus.until)}. Subscribe to keep using Gertrude across all your family’s devices.`;
    case `fullTrialGrace`:
      return `Your Full trial has ended. Subscribe before the grace period ends on ${long(planStatus.until)} to avoid diminished safety on protected Mac computers.`;
  }
}

export function managePlanText(input: Input): string | undefined {
  switch (input.planStatus.case) {
    case `complimentary`:
      return undefined;
    case `free`:
      return `Upgrade plan...`;
    case `light`:
    case `full`:
    case `fullTrial`:
    case `fullTrialGrace`:
      return `Manage plan...`;
  }
}

export function manageBlurb(input: Input): string | undefined {
  const { planStatus, fullTrialStartedAt, lastPaidTier } = input;
  switch (planStatus.case) {
    case `complimentary`:
      return undefined;

    case `full`: {
      if (planStatus.status.case === `current`) {
        return `Your next $10 monthly payment is scheduled for ${long(planStatus.status.renewsAt)}. You can cancel at any time if you no longer need protection.`;
      }
      return `Your $10 monthly payment was due ${long(planStatus.status.since)} but didn't go through. Update your payment method to keep Full access for your family.`;
    }

    case `light`: {
      if (planStatus.status.case === `current`) {
        const cancelSuffix = fullTrialStartedAt
          ? ``
          : ` if you no longer need protection`;
        return `Your next $10 yearly payment is scheduled for ${long(planStatus.status.renewsAt)}. You can cancel at any time${cancelSuffix}.`;
      }
      return `Your $10 yearly payment was due ${long(planStatus.status.since)} but didn't go through. Update your payment method to keep Light access for your family.`;
    }

    case `free`:
      if (fullTrialStartedAt && !lastPaidTier) {
        return `Your free Full trial starting ${long(fullTrialStartedAt)} has ended. Subscribe to keep using Gertrude across all your devices.`;
      }
      if (lastPaidTier === `full`) {
        return `Your previous Full subscription has ended due to non-payment. Subscribe again to restore Mac computer and iOS device protection for your whole family.`;
      }
      if (lastPaidTier === `light`) {
        return `Your Light subscription has ended. Subscribe again to keep supervising your family's iPhones and iPads.`;
      }
      return undefined;

    case `fullTrial`:
    case `fullTrialGrace`:
      return offersLightPurchase(input)
        ? `Note: a Light subscription doesn't include Mac computer support. Subscribing to Light will diminish protection on any protected Mac computers.`
        : undefined;
  }
}

export function actionLabel(action: SubscriptionPanelAction, input: Input): string {
  switch (action.case) {
    case `startCheckout`: {
      const isFreeBrandNew =
        input.planStatus.case === `free` && !input.fullTrialStartedAt;
      const verb = isFreeBrandNew ? `Upgrade to` : `Subscribe to`;
      return `${verb} ${tierName(action.tier)}`;
    }
    case `reactivateViaCheckout`: {
      const previouslyHadThisTier = input.lastPaidTier === action.tier;
      const verb = previouslyHadThisTier ? `Reactivate` : `Subscribe to`;
      return `${verb} ${tierName(action.tier)}`;
    }
    case `upgradeSubscriptionTier`:
      return action.to === `full` ? `Upgrade to Full` : `Switch to Light`;
    case `openBillingPortal`:
      return `Manage subscription...`;
    case `startFullTrial`:
      return `Start 21 day Full free trial`;
  }
}

export function badge(input: Input): BadgeOutput {
  const { planStatus } = input;
  switch (planStatus.case) {
    case `complimentary`:
      return { text: `Complimentary`, type: `ok` };
    case `fullTrial`: {
      const msUntilTrialEnd = new Date(planStatus.until).getTime() - Date.now();
      if (msUntilTrialEnd <= EXPIRING_SOON_THRESHOLD_MS) {
        return { text: `Trial expiring soon`, type: `warning` };
      }
      return { text: `Trialing`, type: `ok` };
    }
    case `fullTrialGrace`:
      return { text: `Trial expired`, type: `red` };
    case `free`:
      return { text: `Free`, type: `info` };
    case `light`:
    case `full`:
      if (planStatus.status.case === `pastDue`) return { text: `Past due`, type: `red` };
      return { text: `Paid`, type: `ok` };
  }
}

// — helpers —

function offersLightPurchase(input: Input): boolean {
  return [input.primary, ...input.secondary].some(
    (a) =>
      a !== undefined &&
      (a.case === `startCheckout` || a.case === `reactivateViaCheckout`) &&
      a.tier === `light`,
  );
}

function tierName(tier: SubscriptionTier): string {
  return tier === `full` ? `Full` : `Light`;
}

function long(iso: string): string {
  return formatDate(new Date(iso), `long`);
}
