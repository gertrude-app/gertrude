import { describe, expect, test } from 'vitest';
import type { GetAccountBilling } from '@shared/pairql/src/account';
import {
  actionLabel,
  actionsByPlan,
  currentPlan,
  planBadge,
  planCardBadge,
  planOverview,
  planTitle,
} from '../billing';

const free: GetAccountBilling.Output = {
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `light` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `full` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`light`, `medium`, `full`],
};

describe(`account billing copy`, () => {
  test(`shows when a canceled subscription ends`, () => {
    const canceling: GetAccountBilling.Output = {
      planStatus: {
        case: `full`,
        status: { case: `current`, renewsAt: `2026-12-11T17:00:00Z` },
      },
      primary: { case: `openBillingPortal`, config: `default` },
      secondary: [],
      availableTiers: [],
      cancelsAt: `2026-12-11T17:00:00Z`,
    };

    expect(planBadge(canceling)).toEqual({ text: `Cancels Dec 11`, color: `yellow` });
    expect(planOverview(canceling)).toEqual([
      `Your Full plan is canceled and ends on Friday, December 11, 2026. You’ll keep access until then. To keep your plan, choose Manage subscription and renew it.`,
    ]);
    expect(planBadge({ ...canceling, cancelsAt: undefined })).toEqual({
      text: `Paid`,
      color: `green`,
    });
  });

  test(`describes a brand-new free account`, () => {
    expect(planTitle(free)).toBe(`Free plan`);
    expect(planBadge(free)).toEqual({ text: `Free`, color: `blue` });
    expect(actionLabel(free.primary!, free)).toBe(`Upgrade to Light`);
    expect(currentPlan(free.planStatus)).toBe(`free`);
  });

  test(`describes past-due plans`, () => {
    const pastDue: GetAccountBilling.Output = {
      planStatus: {
        case: `medium`,
        status: { case: `pastDue`, since: `2026-08-20T00:00:00Z` },
      },
      primary: { case: `openBillingPortal`, config: `mediumTier` },
      secondary: [],
      availableTiers: [],
    };

    expect(planBadge(pastDue)).toEqual({ text: `Past due`, color: `red` });
    expect(actionLabel(pastDue.primary!, pastDue)).toBe(`Update payment method`);
    expect(currentPlan(pastDue.planStatus)).toBe(`medium`);
  });

  test(`labels tier changes in context`, () => {
    const full: GetAccountBilling.Output = {
      planStatus: {
        case: `full`,
        status: { case: `current`, renewsAt: `2026-09-20T00:00:00Z` },
      },
      primary: { case: `openBillingPortal`, config: `default` },
      secondary: [{ case: `changeSubscriptionTier`, to: `medium` }],
      availableTiers: [`medium`],
    };

    expect(actionLabel(full.secondary[0]!, full)).toBe(`Switch to Medium`);
  });

  test(`groups actions with their plan cards`, () => {
    const grouped = actionsByPlan(free);

    expect(grouped.free).toEqual([]);
    expect(grouped.light).toEqual([{ case: `startCheckout`, tier: `light` }]);
    expect(grouped.medium).toEqual([{ case: `startCheckout`, tier: `medium` }]);
    expect(grouped.full).toEqual([
      { case: `startFullTrial` },
      { case: `startCheckout`, tier: `full` },
    ]);
  });

  test(`distinguishes trial access from its paid base plan`, () => {
    const trial: GetAccountBilling.Output = {
      planStatus: {
        case: `fullTrial`,
        until: `2026-09-20T00:00:00Z`,
        substrate: {
          tier: `medium`,
          status: { case: `current`, renewsAt: `2026-10-20T00:00:00Z` },
        },
      },
      primary: { case: `changeSubscriptionTier`, to: `full` },
      secondary: [
        { case: `openBillingPortal`, config: `mediumTier` },
        { case: `changeSubscriptionTier`, to: `light` },
      ],
      availableTiers: [`light`, `full`],
    };

    expect(planCardBadge(trial, `full`)).toEqual({
      text: `Trialing`,
      color: `violet`,
    });
    expect(planCardBadge(trial, `medium`)).toEqual({
      text: `Paid base plan`,
      color: `yellow`,
    });
    expect(actionsByPlan(trial).medium).toEqual([
      { case: `openBillingPortal`, config: `mediumTier` },
    ]);
    expect(planOverview(trial)).toHaveLength(2);
  });
});
