import { SubscriptionPanel } from '@dash/components';
import React from 'react';
import type { SubscriptionPanelAction } from '@dash/types';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'Dashboard/Settings/SubscriptionPanel', // eslint-disable-line
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

const FreeStandard: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [{ case: `startCheckout`, tier: `light` }, { case: `startFullTrial` }],
  availableTiers: [`light`, `full`],
};

const FreeStandardTrialUsed: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [{ case: `startCheckout`, tier: `light` }],
  availableTiers: [`light`, `full`],
  fullTrialStartedAt: inDays(-60),
};

const FreeLapsedLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `reactivateViaCheckout`, tier: `light` },
  secondary: [{ case: `reactivateViaCheckout`, tier: `full` }],
  availableTiers: [`light`, `full`],
  lastPaidTier: `light`,
};

const FreeLapsedFull: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `free` },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [{ case: `reactivateViaCheckout`, tier: `light` }],
  availableTiers: [`light`, `full`],
  lastPaidTier: `full`,
};

const LightPaid: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `light`, status: { case: `current`, renewsAt: inDays(18) } },
  primary: { case: `upgradeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `lightTier` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`full`],
  lastPaidTier: `light`,
};

const LightPaidTrialUsed: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `light`, status: { case: `current`, renewsAt: inDays(22) } },
  primary: { case: `upgradeSubscriptionTier`, to: `full` },
  secondary: [{ case: `openBillingPortal`, config: `lightTier` }],
  availableTiers: [`full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-40),
};

const LightOverdue: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `light`, status: { case: `pastDue`, since: inDays(-2) } },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [{ case: `upgradeSubscriptionTier`, to: `full` }],
  availableTiers: [`full`],
  lastPaidTier: `light`,
};

const FullTrialStandalone: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(14) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [{ case: `startCheckout`, tier: `light` }],
  availableTiers: [`light`, `full`],
  fullTrialStartedAt: inDays(-7),
};

const FullTrialStandaloneExpiring: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(2) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [{ case: `startCheckout`, tier: `light` }],
  availableTiers: [`light`, `full`],
  fullTrialStartedAt: inDays(-19),
};

const FullTrialFromLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(11) },
  primary: { case: `upgradeSubscriptionTier`, to: `full` },
  secondary: [{ case: `openBillingPortal`, config: `lightTier` }],
  availableTiers: [`full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-10),
};

const FullTrialFromLapsedLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrial`, until: inDays(9) },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [{ case: `reactivateViaCheckout`, tier: `light` }],
  availableTiers: [`light`, `full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-12),
};

const FullPaid: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `full`, status: { case: `current`, renewsAt: inDays(24) } },
  primary: { case: `openBillingPortal`, config: `default` },
  secondary: [],
  availableTiers: [],
  lastPaidTier: `full`,
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

const FullTrialGraceStandalone: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrialGrace`, until: inDays(4) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [{ case: `startCheckout`, tier: `light` }],
  availableTiers: [`light`, `full`],
  fullTrialStartedAt: inDays(-24),
};

const FullTrialGraceFromLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrialGrace`, until: inDays(3) },
  primary: { case: `upgradeSubscriptionTier`, to: `full` },
  secondary: [{ case: `openBillingPortal`, config: `lightTier` }],
  availableTiers: [`full`],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-25),
};

const FullTrialGraceFromLapsedLight: PanelArgs = {
  ...baseArgs,
  planStatus: { case: `fullTrialGrace`, until: inDays(2) },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [{ case: `reactivateViaCheckout`, tier: `light` }],
  lastPaidTier: `light`,
  fullTrialStartedAt: inDays(-26),
  availableTiers: [`light`, `full`],
};

const ALL_PANELS: Array<{ label: string; args: PanelArgs }> = [
  { label: `Free — trial expired (57.1%, n=433)`, args: FreeStandardTrialUsed },
  { label: `Free — brand new (18.2%, n=138)`, args: FreeStandard },
  { label: `Full — paid (11.1%, n=84)`, args: FullPaid },
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
  // — below this line: 0 parents in current data —
  { label: `Light — overdue (0%)`, args: LightOverdue },
  { label: `Full trial — from Light (0%)`, args: FullTrialFromLight },
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
    pendingAction: { case: `upgradeSubscriptionTier`, to: `full` },
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
            . If you add or remove a branch there, mirror the change here.
          </p>
          <p>
            Percentages and{` `}
            <code className="text-xs bg-slate-100 px-1 py-0.5 rounded">n</code> are from a
            May 2026 prod-sync snapshot (758 parents total). Tiles are ordered most-common
            to least so the layout focuses on the states the UI must do well; tiles below
            the gap have zero parents in current data and exist for completeness.
          </p>
          <p>
            <strong>NB: standalone</strong> means no current Stripe sub and no prior sub
            on record. A blank-slate user trialing or subscribing for the first time.
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
