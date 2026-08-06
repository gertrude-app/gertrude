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
    case `medium`:
      return `Medium plan`;
    case `complimentary`:
      return `Complimentary`;
    case `full`:
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
    case `medium`:
      return `$5/month. Everything in Light, plus parent-curated music listening with Gertrude Music.`;
    case `complimentary`:
      return `Complete access to all Gertrude apps on all of your family’s devices.`;
    case `full`:
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
    case `medium`:
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

    case `medium`: {
      if (planStatus.status.case === `current`) {
        const cancelSuffix = fullTrialStartedAt
          ? ``
          : ` if you no longer need protection`;
        return `Your next $5 monthly payment is scheduled for ${long(planStatus.status.renewsAt)}. You can cancel at any time${cancelSuffix}.`;
      }
      return `Your $5 monthly payment was due ${long(planStatus.status.since)} but didn't go through. Update your payment method to keep Medium access for your family.`;
    }

    case `free`:
      if (fullTrialStartedAt && !lastPaidTier) {
        return `Your free Full trial starting ${long(fullTrialStartedAt)} has ended. Subscribe to keep using Gertrude across all your devices.`;
      }
      if (lastPaidTier === `full`) {
        return `Your previous Full subscription has ended due to non-payment. Subscribe again to restore Mac computer and iOS device protection for your whole family.`;
      }
      if (lastPaidTier === `medium`) {
        return `Your Medium subscription has ended. Subscribe again to keep supervising your family's iPhones and iPads and using Gertrude Music.`;
      }
      if (lastPaidTier === `light`) {
        return `Your Light subscription has ended. Subscribe again to keep supervising your family's iPhones and iPads.`;
      }
      return undefined;

    case `fullTrial`:
    case `fullTrialGrace`:
      if (planStatus.substrate?.tier === `light`) {
        if (planStatus.substrate.status.case === `pastDue`) {
          return `Your Light payment didn't go through, so iPhone and iPad supervision is paused until you update your payment method. You're also trialing Full.`;
        }
        return `You're trialing Full on top of your paid Light plan. Your iPhone and iPad supervision continues no matter what — upgrade to keep Full’s Mac computer protection, or stay on Light when the trial ends.`;
      }
      if (planStatus.substrate?.tier === `medium`) {
        if (planStatus.substrate.status.case === `pastDue`) {
          return `Your Medium payment didn't go through, so iPhone and iPad supervision and Gertrude Music are paused until you update your payment method. You're also trialing Full.`;
        }
        return `You're trialing Full on top of your paid Medium plan. Your iPhone and iPad supervision and Gertrude Music continue no matter what — upgrade to keep Full’s Mac computer protection, or stay on Medium when the trial ends.`;
      }
      return offersNonFullPurchase(input)
        ? `Note: Light and Medium subscriptions don't include Mac computer support. Choosing one will diminish protection on any protected Mac computers.`
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
    case `changeSubscriptionTier`:
      return changeTierLabel(action.to, input);
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
      return { text: `Active`, type: `ok` };
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
    case `medium`:
    case `full`:
      if (planStatus.status.case === `pastDue`) return { text: `Past due`, type: `red` };
      return { text: `Paid`, type: `ok` };
  }
}

// — helpers —

function offersNonFullPurchase(input: Input): boolean {
  return [input.primary, ...input.secondary].some(
    (a) =>
      a !== undefined &&
      (a.case === `startCheckout` || a.case === `reactivateViaCheckout`) &&
      a.tier !== `full`,
  );
}

function changeTierLabel(to: SubscriptionTier, input: Input): string {
  switch (to) {
    case `full`:
      return `Upgrade to Full`;
    case `medium`:
      return input.planStatus.case === `full` ? `Switch to Medium` : `Upgrade to Medium`;
    case `light`:
      return `Switch to Light`;
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

function long(iso: string): string {
  return formatDate(new Date(iso), `long`);
}
