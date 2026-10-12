import { galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps } from 'react';
import CheckoutResultPage from './CheckoutResultPage';
import SettingsShellPage from './SettingsShellPage';
import AuthedAppLayout from '#/components/layout/AuthedAppLayout';

const meta = {
  title: 'Account/Pages/Settings/Checkout result',
  component: CheckoutResultPage,
  parameters: {
    ...galleryParameters,
    layout: 'fullscreen',
    screenshotsAt: ['mobile', 'desktop'],
  },
  args: { returnHref: `/connect/blockerSupervise/123456` },
  render: (args: ComponentProps<typeof CheckoutResultPage>) => (
    <AuthedAppLayout pathname="/settings/billing" requestCount={0}>
      <SettingsShellPage
        email="parent@example.com"
        selectedHref="/settings/billing"
        notificationsHref="/settings/notifications"
        billingHref="/settings/billing"
        onChangePassword={() => undefined}
      >
        <CheckoutResultPage {...args} />
      </SettingsShellPage>
    </AuthedAppLayout>
  ),
};

export default meta;

export const CheckoutSucceeded = {
  name: 'Checkout succeeded',
  args: { status: `success` } satisfies ComponentProps<typeof CheckoutResultPage>,
};

export const CheckoutCanceled = {
  name: 'Checkout canceled',
  args: { status: `canceled` } satisfies ComponentProps<typeof CheckoutResultPage>,
};
