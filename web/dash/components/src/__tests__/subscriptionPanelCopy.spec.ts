import { describe, expect, it } from 'vitest';
import type { Input } from '../Settings/SubscriptionPanelCopy';
import type { PlanStatus, SubscriptionPanelAction } from '@dash/types';
import {
  actionLabel,
  badge,
  manageBlurb,
  subtext,
  title,
} from '../Settings/SubscriptionPanelCopy';

const RENEWS = `2026-08-07T00:00:00.000Z`;

function input(planStatus: PlanStatus, overrides: Partial<Input> = {}): Input {
  return {
    planStatus,
    primary: undefined,
    secondary: [],
    availableTiers: [],
    ...overrides,
  };
}

const current = { case: `current`, renewsAt: RENEWS } as const;
const pastDue = { case: `pastDue`, since: RENEWS } as const;

describe(`title()`, () => {
  it(`names each paid plan`, () => {
    expect(title(input({ case: `light`, status: current }))).toBe(`Light plan`);
    expect(title(input({ case: `medium`, status: current }))).toBe(`Medium plan`);
    expect(title(input({ case: `full`, status: current }))).toBe(`Full plan`);
  });
});

describe(`subtext()`, () => {
  it(`shows medium price and pitch`, () => {
    expect(subtext(input({ case: `medium`, status: current }))).toContain(`$5/month`);
  });
});

describe(`badge()`, () => {
  it(`shows paid/past-due for medium`, () => {
    expect(badge(input({ case: `medium`, status: current }))).toEqual({
      text: `Paid`,
      type: `ok`,
    });
    expect(badge(input({ case: `medium`, status: pastDue }))).toEqual({
      text: `Past due`,
      type: `red`,
    });
  });
});

describe(`manageBlurb()`, () => {
  it(`describes medium renewal and past due`, () => {
    expect(manageBlurb(input({ case: `medium`, status: current }))).toContain(
      `$5 monthly payment is scheduled`,
    );
    expect(manageBlurb(input({ case: `medium`, status: pastDue }))).toContain(
      `keep Medium access`,
    );
  });

  it(`handles trialing full over paid medium substrate`, () => {
    const trial: PlanStatus = {
      case: `fullTrial`,
      until: RENEWS,
      substrate: { tier: `medium`, status: current },
    };
    expect(manageBlurb(input(trial))).toContain(`paid Medium plan`);
  });
});

describe(`actionLabel()`, () => {
  const light = input({ case: `light`, status: current });
  const medium = input({ case: `medium`, status: current });
  const full = input({ case: `full`, status: current });

  it(`labels tier changes by direction`, () => {
    const toMedium: SubscriptionPanelAction = {
      case: `changeSubscriptionTier`,
      to: `medium`,
    };
    const toFull: SubscriptionPanelAction = {
      case: `changeSubscriptionTier`,
      to: `full`,
    };
    const toLight: SubscriptionPanelAction = {
      case: `changeSubscriptionTier`,
      to: `light`,
    };
    expect(actionLabel(toMedium, light)).toBe(`Upgrade to Medium`); // light -> medium
    expect(actionLabel(toMedium, full)).toBe(`Switch to Medium`); // full -> medium
    expect(actionLabel(toFull, medium)).toBe(`Upgrade to Full`);
    expect(actionLabel(toLight, medium)).toBe(`Switch to Light`);
  });

  it(`names all three tiers in checkout labels`, () => {
    const free = input({ case: `free` });
    for (const [tier, name] of [
      [`light`, `Light`],
      [`medium`, `Medium`],
      [`full`, `Full`],
    ] as const) {
      expect(actionLabel({ case: `startCheckout`, tier }, free)).toBe(
        `Upgrade to ${name}`,
      );
    }
  });
});
