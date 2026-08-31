import { formatDate } from '@shared/datetime';
import type {
  BillingStatus,
  GetAccountBilling,
  PlanStatus,
  SubscriptionPanelAction,
  SubscriptionTier,
} from '@shared/pairql/src/account';

type Input = GetAccountBilling.Output;
export type CurrentPlan = `free` | `light` | `medium` | `full`;

const EXPIRING_SOON_THRESHOLD_MS = 3 * 24 * 60 * 60 * 1000;

export const PLAN_FEATURES: Record<
  CurrentPlan,
  {
    name: string;
    price: string;
    cadence?: string;
    billingNote?: string;
    features: string[];
  }
> = {
  free: {
    name: `Free`,
    price: `$0`,
    features: [`Protect iPhones and iPads for kids under 18 with Gertrude Blocker`],
  },
  light: {
    name: `Light`,
    price: `83¢`,
    cadence: `per month`,
    billingNote: `Billed $10 annually`,
    features: [
      `Everything in Free`,
      `Parent-curated podcast listening with Gertrude Podcasts`,
      `Protect supervised iPhones and iPads for adults 18+`,
      `Additional supervision-only restrictions`,
    ],
  },
  medium: {
    name: `Medium`,
    price: `$5`,
    cadence: `per month`,
    features: [
      `Everything in Light`,
      `Parent-curated music listening with Gertrude Music`,
    ],
  },
  full: {
    name: `Full`,
    price: `$10`,
    cadence: `per month`,
    features: [
      `Everything in Medium`,
      `Mac internet filtering, screenshots, app blocking, downtime, and more`,
    ],
  },
};

export function planTitle(input: Input): string {
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

export function planSubtext(input: Input): string {
  const { planStatus } = input;
  switch (planStatus.case) {
    case `free`:
      return `Protect child iPhones and iPads with Gertrude Blocker.`;
    case `light`:
      return `$10/year. Protect child and adult supervised iPhones and iPads.`;
    case `medium`:
      return `$5/month. Everything in Light, plus parent-curated music listening with Gertrude Music.`;
    case `complimentary`:
      return `Complete access to all Gertrude apps on all of your family’s devices.`;
    case `full`:
      return `$10/month. Protect and monitor Macs, iPhones, and iPads for the whole family.`;
    case `fullTrial`:
      return `Your free trial ends ${long(planStatus.until)}. Subscribe to keep using Gertrude across all your family’s devices.`;
    case `fullTrialGrace`:
      return `Your Full trial has ended. Subscribe before the grace period ends on ${long(planStatus.until)} to avoid diminished safety on protected Macs.`;
  }
}

export function manageBlurb(input: Input): string | undefined {
  const { planStatus, fullTrialStartedAt, lastPaidTier } = input;
  switch (planStatus.case) {
    case `complimentary`:
      return undefined;
    case `full`:
      return planStatus.status.case === `current`
        ? `Your next $10 monthly payment is scheduled for ${long(planStatus.status.renewsAt)}. You can cancel at any time if you no longer need protection.`
        : `Your $10 monthly payment was due ${long(planStatus.status.since)} but didn't go through. Update your payment method to keep Full access for your family.`;
    case `light`: {
      if (planStatus.status.case === `pastDue`) {
        return `Your $10 yearly payment was due ${long(planStatus.status.since)} but didn't go through. Update your payment method to keep Light access for your family.`;
      }
      const cancelSuffix = fullTrialStartedAt ? `` : ` if you no longer need protection`;
      return `Your next $10 yearly payment is scheduled for ${long(planStatus.status.renewsAt)}. You can cancel at any time${cancelSuffix}.`;
    }
    case `medium`: {
      if (planStatus.status.case === `pastDue`) {
        return `Your $5 monthly payment was due ${long(planStatus.status.since)} but didn't go through. Update your payment method to keep Medium access for your family.`;
      }
      const cancelSuffix = fullTrialStartedAt ? `` : ` if you no longer need protection`;
      return `Your next $5 monthly payment is scheduled for ${long(planStatus.status.renewsAt)}. You can cancel at any time${cancelSuffix}.`;
    }
    case `free`:
      if (fullTrialStartedAt && !lastPaidTier) {
        return `Your free Full trial starting ${long(fullTrialStartedAt)} has ended. Subscribe to keep using Gertrude across all your devices.`;
      }
      if (lastPaidTier === `full`) {
        return `Your previous Full subscription ended due to non-payment. Subscribe again to restore protection for your family.`;
      }
      if (lastPaidTier === `medium`) {
        return `Your Medium subscription has ended. Subscribe again to keep iPhone and iPad supervision and Gertrude Music.`;
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
        return `You're trialing Full on top of Light. Your iPhone and iPad supervision continues either way—upgrade to keep Full’s Mac protection, or stay on Light when the trial ends.`;
      }
      if (planStatus.substrate?.tier === `medium`) {
        if (planStatus.substrate.status.case === `pastDue`) {
          return `Your Medium payment didn't go through, so supervision and Gertrude Music are paused until you update your payment method. You're also trialing Full.`;
        }
        return `You're trialing Full on top of Medium. Your supervision and Gertrude Music continue either way—upgrade to keep Full’s Mac protection, or stay on Medium.`;
      }
      return offersNonFullPurchase(input)
        ? `Light and Medium don't include Mac support. Choosing one will diminish protection on protected Macs.`
        : undefined;
  }
}

export function actionLabel(action: SubscriptionPanelAction, input: Input): string {
  switch (action.case) {
    case `startCheckout`: {
      const isBrandNew = input.planStatus.case === `free` && !input.fullTrialStartedAt;
      return `${isBrandNew ? `Upgrade to` : `Subscribe to`} ${tierName(action.tier)}`;
    }
    case `reactivateViaCheckout`:
      return `${input.lastPaidTier === action.tier ? `Reactivate` : `Subscribe to`} ${tierName(action.tier)}`;
    case `changeSubscriptionTier`:
      return changeTierLabel(action.to, input);
    case `openBillingPortal`:
      return billingStatus(input.planStatus)?.case === `pastDue`
        ? `Update payment method`
        : `Manage subscription`;
    case `startFullTrial`:
      return `Start 21-day free trial`;
  }
}

export function planOverview(input: Input): string[] {
  const overview = manageBlurb(input);
  if (
    input.planStatus.case === `fullTrial` ||
    input.planStatus.case === `fullTrialGrace`
  ) {
    return overview ? [planSubtext(input), overview] : [planSubtext(input)];
  }
  return [overview ?? planSubtext(input)];
}

export function actionsByPlan(
  input: Input,
): Record<CurrentPlan, SubscriptionPanelAction[]> {
  const grouped: Record<CurrentPlan, SubscriptionPanelAction[]> = {
    free: [],
    light: [],
    medium: [],
    full: [],
  };
  const actions = input.primary ? [input.primary, ...input.secondary] : input.secondary;
  for (const action of actions) {
    grouped[actionPlan(action)].push(action);
  }
  if (grouped.full.some((action) => action.case === `startFullTrial`)) {
    grouped.full = grouped.full.filter((action) => action.case === `startFullTrial`);
  }
  return grouped;
}

export function planCardBadge(
  input: Input,
  tier: CurrentPlan,
):
  | {
      text: string;
      color: `violet` | `red` | `yellow` | `neutral`;
    }
  | undefined {
  const { planStatus } = input;
  if (tier === currentPlan(planStatus)) {
    switch (planStatus.case) {
      case `complimentary`:
        return { text: `Complimentary`, color: `violet` };
      case `fullTrial`:
        return { text: `Trialing`, color: `violet` };
      case `fullTrialGrace`:
        return { text: `Trial expired`, color: `red` };
      case `light`:
      case `medium`:
      case `full`:
        return planStatus.status.case === `pastDue`
          ? { text: `Past due`, color: `red` }
          : { text: `Current`, color: `violet` };
      case `free`:
        return { text: `Current`, color: `neutral` };
    }
  }

  if (
    (planStatus.case === `fullTrial` || planStatus.case === `fullTrialGrace`) &&
    planStatus.substrate?.tier === tier
  ) {
    return planStatus.substrate.status.case === `pastDue`
      ? { text: `Past-due base plan`, color: `red` }
      : { text: `Paid base plan`, color: `yellow` };
  }

  return undefined;
}

export function planBadge(input: Input): {
  text: string;
  color: `blue` | `green` | `red` | `yellow`;
} {
  const { planStatus } = input;
  switch (planStatus.case) {
    case `complimentary`:
      return { text: `Active`, color: `green` };
    case `fullTrial`: {
      const msUntilTrialEnd = new Date(planStatus.until).getTime() - Date.now();
      return msUntilTrialEnd <= EXPIRING_SOON_THRESHOLD_MS
        ? { text: `Trial expiring soon`, color: `yellow` }
        : { text: `Trialing`, color: `green` };
    }
    case `fullTrialGrace`:
      return { text: `Trial expired`, color: `red` };
    case `free`:
      return { text: `Free`, color: `blue` };
    case `light`:
    case `medium`:
    case `full`:
      return planStatus.status.case === `pastDue`
        ? { text: `Past due`, color: `red` }
        : { text: `Paid`, color: `green` };
  }
}

export function currentPlan(planStatus: PlanStatus): CurrentPlan {
  switch (planStatus.case) {
    case `free`:
      return `free`;
    case `light`:
      return `light`;
    case `medium`:
      return `medium`;
    case `full`:
    case `complimentary`:
    case `fullTrial`:
    case `fullTrialGrace`:
      return `full`;
  }
}

export function actionKey(action: SubscriptionPanelAction): string {
  switch (action.case) {
    case `startCheckout`:
    case `reactivateViaCheckout`:
      return `${action.case}-${action.tier}`;
    case `openBillingPortal`:
      return `${action.case}-${action.config}`;
    case `changeSubscriptionTier`:
      return `${action.case}-${action.to}`;
    case `startFullTrial`:
      return action.case;
  }
}

function actionPlan(action: SubscriptionPanelAction): CurrentPlan {
  switch (action.case) {
    case `startCheckout`:
    case `reactivateViaCheckout`:
      return action.tier;
    case `changeSubscriptionTier`:
      return action.to;
    case `startFullTrial`:
      return `full`;
    case `openBillingPortal`:
      switch (action.config) {
        case `lightTier`:
          return `light`;
        case `mediumTier`:
          return `medium`;
        case `default`:
          return `full`;
      }
  }
}

function billingStatus(planStatus: PlanStatus): BillingStatus | undefined {
  switch (planStatus.case) {
    case `light`:
    case `medium`:
    case `full`:
      return planStatus.status;
    case `fullTrial`:
    case `fullTrialGrace`:
      return planStatus.substrate?.status;
    case `free`:
    case `complimentary`:
      return undefined;
  }
}

function offersNonFullPurchase(input: Input): boolean {
  return [input.primary, ...input.secondary].some(
    (action) =>
      action !== undefined &&
      (action.case === `startCheckout` || action.case === `reactivateViaCheckout`) &&
      action.tier !== `full`,
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
