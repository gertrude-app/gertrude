import { SubscriptionPanel } from '@dash/components';
import React from 'react';
import type { SubscriptionPanelAction } from '@dash/types';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'Dashboard/Settings/SubscriptionPanel',
  component: SubscriptionPanel,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof SubscriptionPanel>;

const inDays = (n: number): string =>
  new Date(Date.now() + n * 24 * 60 * 60 * 1000).toISOString();

type PanelArgs = Omit<React.ComponentProps<typeof SubscriptionPanel>, `onAction`>;

const baseArgs = {
  primary: undefined,
  secondary: [],
  availableTiers: [],
};

// — free, no history —

const FreeStandard: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `light` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `full` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`light`, `medium`, `full`],
};

const FreeStandardTrialUsed: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `light` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `full` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-60),
};

// — free, lapsed —

const FreeLapsedLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `reactivateViaCheckout`, tier: `light` },
  secondary: [
    { case: `reactivateViaCheckout`, tier: `medium` },
    { case: `reactivateViaCheckout`, tier: `full` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  lastPaidTier: `light`,
};

const FreeLapsedFull: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [
    { case: `reactivateViaCheckout`, tier: `medium` },
    { case: `reactivateViaCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  lastPaidTier: `full`,
};

const FreeLapsedMedium: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `reactivateViaCheckout`, tier: `medium` },
  secondary: [
    { case: `reactivateViaCheckout`, tier: `full` },
    { case: `reactivateViaCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  lastPaidTier: `medium`,
};

// — light tier —

const LightPaid: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `light`, status: { case: `current`, renewsAt: inDays(18) } },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
};

const LightPaidTrialUsed: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `light`, status: { case: `current`, renewsAt: inDays(22) } },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `full` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-40),
};

const LightOverdue: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `light`, status: { case: `pastDue`, since: inDays(-2) } },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `full` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
};

// — medium tier —

const MediumPaid: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `medium`, status: { case: `current`, renewsAt: inDays(26) } },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
};

const MediumPaidTrialUsed: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `medium`, status: { case: `current`, renewsAt: inDays(20) } },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-40),
};

const MediumOverdue: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `medium`, status: { case: `pastDue`, since: inDays(-2) } },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
};

// — full trial (within trial window) —

const FullTrialStandalone: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(14) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-7),
};

const FullTrialStandaloneExpiring: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(2) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-19),
};

const FullTrialFromLight: PanelArgs = {
  ...baseArgs,
  planStatus: {
    case: `fullTrial`,
    until: inDays(11),
    substrate: { tier: `light`, status: { case: `current`, renewsAt: inDays(200) } },
  },
  primary: { case: `changeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `lightTier` },
    { case: `changeSubscriptionTier`, to: `medium` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-10),
};

const FullTrialFromMedium: PanelArgs = {
  ...baseArgs,
  planStatus: {
    case: `fullTrial`,
    until: inDays(11),
    substrate: { tier: `medium`, status: { case: `current`, renewsAt: inDays(20) } },
  },
  primary: { case: `changeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `mediumTier` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-10),
};

const FullTrialFromPastDueLight: PanelArgs = {
  ...baseArgs,
  planStatus: {
    case: `fullTrial`,
    until: inDays(9),
    substrate: { tier: `light`, status: { case: `pastDue`, since: inDays(-3) } },
  },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `full` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-12),
};

const FullTrialFromPastDueMedium: PanelArgs = {
  ...baseArgs,
  planStatus: {
    case: `fullTrial`,
    until: inDays(9),
    substrate: { tier: `medium`, status: { case: `pastDue`, since: inDays(-3) } },
  },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-12),
};

const FullTrialFromLapsedLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(9) },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [
    { case: `reactivateViaCheckout`, tier: `medium` },
    { case: `reactivateViaCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-12),
};

// — full tier —

const FullPaid: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `full`, status: { case: `current`, renewsAt: inDays(24) } },
  primary: { case: `openBillingPortal`, config: `default` },
  secondary: [],
  availableTiers: [],
  lastPaidTier: `full`,
};

const FullPaidNoMacs: PanelArgs = {
  ...FullPaid,
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `medium`],
};

const FullOverdue: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `full`, status: { case: `pastDue`, since: inDays(-3) } },
  primary: { case: `openBillingPortal`, config: `default` },
  secondary: [],
  availableTiers: [],
  lastPaidTier: `full`,
};

const FullComplimentary: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `complimentary` },
  primary: undefined,
  secondary: [],
  availableTiers: [],
};

// — full trial grace (post-trial, within grace period) —

const FullTrialGraceStandalone: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrialGrace`, until: inDays(4) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-24),
};

const FullTrialGraceFromLight: PanelArgs = {
  ...baseArgs,
  planStatus: {
    case: `fullTrialGrace`,
    until: inDays(3),
    substrate: { tier: `light`, status: { case: `current`, renewsAt: inDays(200) } },
  },
  primary: { case: `changeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `lightTier` },
    { case: `changeSubscriptionTier`, to: `medium` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-25),
};

const FullTrialGraceFromMedium: PanelArgs = {
  ...baseArgs,
  planStatus: {
    case: `fullTrialGrace`,
    until: inDays(3),
    substrate: { tier: `medium`, status: { case: `current`, renewsAt: inDays(20) } },
  },
  primary: { case: `changeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `mediumTier` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-25),
};

const FullTrialGraceFromLapsedLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrialGrace`, until: inDays(2) },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [
    { case: `reactivateViaCheckout`, tier: `medium` },
    { case: `reactivateViaCheckout`, tier: `light` },
  ],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-26),
  availableTiers: [`light`, `medium`, `full`],
};

const ALL_PANELS: Array<{ label: string; args: PanelArgs }> = [
  { label: `Free — trial expired (57.1%, n=433)`, args: FreeStandardTrialUsed },
  { label: `Free — brand new (18.2%, n=138)`, args: FreeStandard },
  { label: `Full — paid (11.1%, n=84)`, args: FullPaid },
  { label: `Full — paid, no Macs (sub-state)`, args: FullPaidNoMacs },
  { label: `Light — paid (5.7%, n=43)`, args: LightPaid },
  { label: `Full — complimentary (3.4%, n=26)`, args: FullComplimentary },
  { label: `Free — lapsed Full (2.9%, n=22)`, args: FreeLapsedFull },
  { label: `Full trial — standalone (0.8%, n=6)`, args: FullTrialStandalone },
  {
    label: `Full trial — standalone, expiring (sub-state)`,
    args: FullTrialStandaloneExpiring,
  },
  { label: `Light — paid, trial used (0.4%, n=3)`, args: LightPaidTrialUsed },
  { label: `Free — lapsed Light (0.3%, n=2)`, args: FreeLapsedLight },
  { label: `Full — overdue (0.1%, n=1)`, args: FullOverdue },
  // — below this line: pre-release Medium tier + zero-population states —
  { label: `Medium — paid (pre-release)`, args: MediumPaid },
  { label: `Medium — paid, trial used (pre-release)`, args: MediumPaidTrialUsed },
  { label: `Medium — overdue (pre-release)`, args: MediumOverdue },
  { label: `Free — lapsed Medium (pre-release)`, args: FreeLapsedMedium },
  { label: `Full trial — from Medium (pre-release)`, args: FullTrialFromMedium },
  {
    label: `Full trial — from past-due Medium (pre-release)`,
    args: FullTrialFromPastDueMedium,
  },
  {
    label: `Full trial grace — from Medium (pre-release)`,
    args: FullTrialGraceFromMedium,
  },
  { label: `Light — overdue (0%)`, args: LightOverdue },
  { label: `Full trial — from Light (0%)`, args: FullTrialFromLight },
  { label: `Full trial — from past-due Light (0%)`, args: FullTrialFromPastDueLight },
  { label: `Full trial — from lapsed Light (0%)`, args: FullTrialFromLapsedLight },
  { label: `Full trial grace — standalone (0%)`, args: FullTrialGraceStandalone },
  { label: `Full trial grace — from Light (0%)`, args: FullTrialGraceFromLight },
  {
    label: `Full trial grace — from lapsed Light (0%)`,
    args: FullTrialGraceFromLapsedLight,
  },
];

// Pending state. Click "Manage plan..." to see the action buttons disabled.
export const Pending: StoryObj<typeof SubscriptionPanel> = {
  args: {
    ...LightPaid,
    pendingAction: { case: `changeSubscriptionTier`, to: `medium` },
  },
};

export const AllStates: StoryObj<typeof SubscriptionPanel> = {
  render: () => {
    const noop = (_: SubscriptionPanelAction): void => {};
    return (
      <div className="p-8 bg-white min-h-screen">
        <header className="*max-w-3xl mb-8 space-y-3 text-sm text-slate-700">
          <h1 className="text-2xl font-bold text-slate-900">
            SubscriptionPanel — all states
          </h1>
          <p>
            Every tile below is a distinct shape that{` `}
            <code className="text-xs bg-slate-100 px-1 py-0.5 rounded">
              GetSubscriptionPanel_v2.Output
            </code>
            {` `}can take. The matrix mirrors the branches of the resolver at{` `}
            <code className="text-xs bg-slate-100 px-1 py-0.5 rounded">
              swift/api/Sources/Api/PairQL/Dashboard/Pairs/GetSubscriptionPanel_v2.swift
            </code>
            {` `}(and the cases enumerated in{` `}
            <code className="text-xs bg-slate-100 px-1 py-0.5 rounded">
              SubscriptionPanelTests.swift
            </code>
            ). If you add or remove a branch there, mirror the change here.
          </p>
          <p>
            Percentages and{` `}
            <code className="text-xs bg-slate-100 px-1 py-0.5 rounded">n</code> are from a
            May 2026 prod-sync snapshot (758 parents total). Tiles are ordered most-common
            to least so the layout focuses on the states the UI must do well; tiles below
            the gap have zero parents in current data and exist for completeness. The{` `}
            <strong>Medium</strong> tier ($5/mo) is pre-release, so all Medium states
            currently have zero population.
          </p>
          <p>
            <strong>NB: standalone</strong> means no current Stripe sub and no prior sub
            on record — a blank-slate user trialing or subscribing for the first time.
            {` `}
            <strong>from Light / from Medium</strong> trial states have a paid{` `}
            <em>substrate</em> subscription underneath the Full trial (supervision/music
            keep running); <strong>from lapsed</strong> means a prior sub exists but is no
            longer live.
          </p>
        </header>
        <div
          className="grid gap-6"
          style={{ gridTemplateColumns: `repeat(auto-fill, minmax(320px, 1fr))` }}
        >
          {ALL_PANELS.map(({ label, args }) => (
            <div key={label} className="flex flex-col">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-500 mb-2">
                {label}
              </p>
              <div className="flex-1">
                <SubscriptionPanel {...args} onAction={noop} />
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  },
};

export default meta;
