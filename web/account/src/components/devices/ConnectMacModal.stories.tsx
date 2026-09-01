import { StoryCanvas, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ConnectMacState } from './ConnectMacModal';
import ConnectMacModal from './ConnectMacModal';

const noop = (): void => {};

const meta = {
  title: 'Account/Devices/Connect Mac Modal',
  component: ConnectMacModal,
  parameters: { layout: 'fullscreen' },
};

export default meta;

const renderModal = (state: ConnectMacState) => (
  <StoryCanvas>
    <ConnectMacModal
      open
      onOpenChange={noop}
      personName="Jude"
      state={state}
      onRequestCode={noop}
      onStartTrial={noop}
    />
  </StoryCanvas>
);

export const Instructions = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => renderModal({ case: `instructions` }),
};

export const RequestingCode = {
  name: 'Requesting code',
  parameters: galleryParameters,
  render: () => renderModal({ case: `instructions`, requesting: true }),
};

export const ConnectionCode = {
  name: 'Connection code',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => renderModal({ case: `ready`, code: 481_920 }),
};

export const TrialRequired = {
  name: 'Trial required',
  parameters: galleryParameters,
  render: () => renderModal({ case: `trialRequired` }),
};

export const StartingTrial = {
  name: 'Starting trial',
  parameters: galleryParameters,
  render: () => renderModal({ case: `trialRequired`, startingTrial: true }),
};

export const UpgradeRequired = {
  name: 'Upgrade required',
  parameters: galleryParameters,
  render: () => renderModal({ case: `planUpgradeRequired` }),
};

export const SubscriptionInactive = {
  name: 'Subscription inactive',
  parameters: galleryParameters,
  render: () => renderModal({ case: `subscriptionFixRequired` }),
};

export const Error = {
  parameters: galleryParameters,
  render: () =>
    renderModal({
      case: `error`,
      message: `Connection codes aren't available right now. Try again in a moment.`,
    }),
};
