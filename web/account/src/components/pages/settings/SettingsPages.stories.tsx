import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { GetAccountBilling } from '@shared/pairql/src/account';
import BillingSettingsPage from './BillingSettingsPage';
import NotificationSettingsPage from './NotificationSettingsPage';
import SettingsShellPage from './SettingsShellPage';
import { notificationMethods, notifications } from '#/components/storybook/fixtures';

const noop = (): void => {};
const asyncNoop = async (): Promise<void> => {};
const createPending = async (): Promise<{ methodId: string }> => ({
  methodId: `method-preview`,
});
const confirmPending = async (): Promise<void> => {};

type Billing = GetAccountBilling.Output;

const inDays = (days: number): string =>
  new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString();

const billingFixture = (
  input: Omit<Billing, `secondary` | `availableTiers`> &
    Partial<Pick<Billing, `secondary` | `availableTiers`>>,
): Billing => ({ secondary: [], availableTiers: [], ...input });

const freeNew = billingFixture({
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `light` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `full` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`light`, `medium`, `full`],
});

const freeTrialUsed = billingFixture({
  planStatus: { case: `free` },
  primary: { case: `startCheckout`, tier: `light` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `full` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-60),
});

const freeLapsedFull = billingFixture({
  planStatus: { case: `free` },
  primary: { case: `reactivateViaCheckout`, tier: `full` },
  secondary: [
    { case: `reactivateViaCheckout`, tier: `medium` },
    { case: `reactivateViaCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  lastPaidTier: `full`,
});

const lightCurrent = billingFixture({
  planStatus: {
    case: `light`,
    status: { case: `current`, renewsAt: inDays(180) },
  },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
});

const lightPastDue = billingFixture({
  planStatus: {
    case: `light`,
    status: { case: `pastDue`, since: inDays(-2) },
  },
  primary: { case: `openBillingPortal`, config: `lightTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `full` },
  ],
  availableTiers: [`medium`, `full`],
  lastPaidTier: `light`,
});

const mediumCurrent = billingFixture({
  planStatus: {
    case: `medium`,
    status: { case: `current`, renewsAt: `2026-09-25T00:00:00Z` },
  },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
    { case: `startFullTrial` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
});

const mediumPastDue = billingFixture({
  planStatus: {
    case: `medium`,
    status: { case: `pastDue`, since: inDays(-2) },
  },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
});

const fullCurrent = billingFixture({
  planStatus: {
    case: `full`,
    status: { case: `current`, renewsAt: inDays(24) },
  },
  primary: { case: `openBillingPortal`, config: `default` },
  lastPaidTier: `full`,
});

const fullCurrentSwitchable = billingFixture({
  ...fullCurrent,
  secondary: [
    { case: `changeSubscriptionTier`, to: `medium` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `medium`],
});

const fullPastDue = billingFixture({
  planStatus: {
    case: `full`,
    status: { case: `pastDue`, since: inDays(-3) },
  },
  primary: { case: `openBillingPortal`, config: `default` },
  lastPaidTier: `full`,
});

const complimentary = billingFixture({
  planStatus: { case: `complimentary` },
});

const fullTrial = billingFixture({
  planStatus: { case: `fullTrial`, until: inDays(14) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-7),
});

const fullTrialExpiring = billingFixture({
  ...fullTrial,
  planStatus: { case: `fullTrial`, until: inDays(2) },
  fullTrialStartedAt: inDays(-19),
});

const fullTrialFromMedium = billingFixture({
  planStatus: {
    case: `fullTrial`,
    until: inDays(11),
    substrate: {
      tier: `medium`,
      status: { case: `current`, renewsAt: inDays(20) },
    },
  },
  primary: { case: `changeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `mediumTier` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-10),
});

const fullTrialFromPastDueMedium = billingFixture({
  planStatus: {
    case: `fullTrial`,
    until: inDays(9),
    substrate: {
      tier: `medium`,
      status: { case: `pastDue`, since: inDays(-3) },
    },
  },
  primary: { case: `openBillingPortal`, config: `mediumTier` },
  secondary: [
    { case: `changeSubscriptionTier`, to: `full` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-12),
});

const fullTrialGrace = billingFixture({
  planStatus: { case: `fullTrialGrace`, until: inDays(4) },
  primary: { case: `startCheckout`, tier: `full` },
  secondary: [
    { case: `startCheckout`, tier: `medium` },
    { case: `startCheckout`, tier: `light` },
  ],
  availableTiers: [`light`, `medium`, `full`],
  fullTrialStartedAt: inDays(-24),
});

const fullTrialGraceFromMedium = billingFixture({
  planStatus: {
    case: `fullTrialGrace`,
    until: inDays(3),
    substrate: {
      tier: `medium`,
      status: { case: `current`, renewsAt: inDays(20) },
    },
  },
  primary: { case: `changeSubscriptionTier`, to: `full` },
  secondary: [
    { case: `openBillingPortal`, config: `mediumTier` },
    { case: `changeSubscriptionTier`, to: `light` },
  ],
  availableTiers: [`light`, `full`],
  lastPaidTier: `medium`,
  fullTrialStartedAt: inDays(-25),
});

const meta = {
  title: 'Account/Pages/Settings',
  parameters: { layout: 'fullscreen' },
};

export default meta;

interface BillingStoryProps {
  billing: Billing;
}

const BillingStory: React.FC<BillingStoryProps> = ({ billing }) => (
  <StoryScreen>
    <SettingsShellPage
      email="parent@example.com"
      selectedHref="/settings/billing"
      notificationsHref="/settings/notifications"
      billingHref="/settings/billing"
      onChangePassword={noop}
    >
      <BillingSettingsPage billing={billing} onAction={noop} />
    </SettingsShellPage>
  </StoryScreen>
);

const billingStory = (billing: Billing) => ({
  parameters: galleryParameters,
  render: () => <BillingStory billing={billing} />,
});

export const Notifications = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen>
      <SettingsShellPage
        email="parent@example.com"
        selectedHref="/settings/notifications"
        notificationsHref="/settings/notifications"
        billingHref="/settings/billing"
        onChangePassword={noop}
      >
        <NotificationSettingsPage
          accountEmail="parent@example.com"
          dailyReviewEmail
          hasMacScreenshotUsers
          settingDailyReviewEmail={false}
          notificationMethods={notificationMethods}
          notifications={notifications}
          onSetDailyReviewEmail={noop}
          onCreatePendingMethod={createPending}
          onConfirmPendingMethod={confirmPending}
          onDeleteMethod={noop}
          onCreateNotification={asyncNoop}
          onUpdateNotification={asyncNoop}
          onDeleteNotification={noop}
        />
      </SettingsShellPage>
    </StoryScreen>
  ),
};

export const Billing = {
  name: 'Billing — Medium, current',
  ...billingStory(mediumCurrent),
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
};

export const BillingFreeNew = {
  name: 'Billing — Free, new account',
  ...billingStory(freeNew),
};

export const BillingFreeTrialUsed = {
  name: 'Billing — Free, trial used',
  ...billingStory(freeTrialUsed),
};

export const BillingFreeLapsedFull = {
  name: 'Billing — Free, lapsed Full',
  ...billingStory(freeLapsedFull),
};

export const BillingLightCurrent = {
  name: 'Billing — Light, current',
  ...billingStory(lightCurrent),
};

export const BillingLightPastDue = {
  name: 'Billing — Light, past due',
  ...billingStory(lightPastDue),
};

export const BillingMediumPastDue = {
  name: 'Billing — Medium, past due',
  ...billingStory(mediumPastDue),
};

export const BillingFullCurrent = {
  name: 'Billing — Full, current',
  ...billingStory(fullCurrent),
};

export const BillingFullCurrentSwitchable = {
  name: 'Billing — Full, no Macs',
  ...billingStory(fullCurrentSwitchable),
};

export const BillingFullPastDue = {
  name: 'Billing — Full, past due',
  ...billingStory(fullPastDue),
};

export const BillingComplimentary = {
  name: 'Billing — Complimentary',
  ...billingStory(complimentary),
};

export const BillingFullTrial = {
  name: 'Billing — Full trial',
  ...billingStory(fullTrial),
};

export const BillingFullTrialExpiring = {
  name: 'Billing — Full trial, expiring',
  ...billingStory(fullTrialExpiring),
};

export const BillingFullTrialFromMedium = {
  name: 'Billing — Full trial from Medium',
  ...billingStory(fullTrialFromMedium),
};

export const BillingFullTrialFromPastDueMedium = {
  name: 'Billing — Full trial from past-due Medium',
  ...billingStory(fullTrialFromPastDueMedium),
};

export const BillingFullTrialGrace = {
  name: 'Billing — Full trial grace',
  ...billingStory(fullTrialGrace),
};

export const BillingFullTrialGraceFromMedium = {
  name: 'Billing — Full trial grace from Medium',
  ...billingStory(fullTrialGraceFromMedium),
};
