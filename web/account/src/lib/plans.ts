export const PLAN_IDS = [`free`, `light`, `medium`, `full`] as const;

export type PlanId = (typeof PLAN_IDS)[number];

export interface PlanPrice {
  cents: number;
  interval?: `month` | `year`;
}

export const FEATURES = {
  blocker: `Protect iPhones and iPads for kids under 18 with Gertrude Blocker`,
  podcasts: `Parent- or accountability partner-curated podcast listening with Gertrude Podcasts`,
  supervision: `Protect supervised iPhones and iPads for adults 18+`,
  supervisionRestrictions: `Additional supervision-only restrictions`,
  music: `Parent- or accountability partner-curated music listening with Gertrude Music`,
  macProtection: `Mac internet filtering, app blocking, and downtime`,
  macMonitoring: `Mac screenshot and keystroke monitoring`,
  macRequests: `Mac unlock requests and parent-approved filter suspensions`,
};

export type FeatureId = keyof typeof FEATURES;

interface Plan {
  name: string;
  price: PlanPrice;
  includes?: PlanId;
  features: FeatureId[];
}

export const PLANS: Record<PlanId, Plan> = {
  free: {
    name: `Free`,
    price: { cents: 0 },
    features: [`blocker`],
  },
  light: {
    name: `Light`,
    price: { cents: 1000, interval: `year` },
    includes: `free`,
    features: [`podcasts`, `supervision`, `supervisionRestrictions`],
  },
  medium: {
    name: `Medium`,
    price: { cents: 500, interval: `month` },
    includes: `light`,
    features: [`music`],
  },
  full: {
    name: `Full`,
    price: { cents: 1000, interval: `month` },
    includes: `medium`,
    features: [`macProtection`, `macMonitoring`, `macRequests`],
  },
};

export function planFeatures(plan: PlanId): FeatureId[] {
  const { includes, features } = PLANS[plan];
  return [...(includes ? planFeatures(includes) : []), ...features];
}

export function formatPriceAmount(cents: number): string {
  return new Intl.NumberFormat(`en-US`, {
    style: `currency`,
    currency: `USD`,
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

export function planPriceDisplay(price: PlanPrice): {
  amount: string;
  cadence?: string;
  billingNote?: string;
} {
  const monthlyCents =
    price.interval === `year` ? Math.round(price.cents / 12) : price.cents;
  return {
    amount:
      monthlyCents > 0 && monthlyCents < 100
        ? `${monthlyCents}¢`
        : formatPriceAmount(monthlyCents),
    cadence: price.interval ? `per month` : undefined,
    billingNote:
      price.interval === `year`
        ? `${formatPriceAmount(price.cents)} billed yearly`
        : undefined,
  };
}
