import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import SupervisionSetupPage from './SupervisionSetupPage';

type Props = ComponentProps<typeof SupervisionSetupPage>;

const noop = (): void => {};
const shared = {
  device: {
    type: `iPhone` as const,
    modelName: `iPhone 15 Pro`,
    modelIdentifier: `iPhone16,1`,
  },
  personName: `Jude`,
  onPrimary: noop,
  onFinishLater: noop,
};

const renderPage = (props: Props): ReactElement => (
  <StoryScreen>
    <SupervisionSetupPage {...props} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Connect iOS App/Supervision setup',
  component: SupervisionSetupPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const SubscriptionRequired = {
  name: 'Subscription required',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `plan` }),
};

export const CheckoutCanceled = {
  name: 'Checkout canceled',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `plan`, canceled: true }),
};

export const SubscriptionError = {
  name: 'Subscription error',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      stage: `plan`,
      error: `Couldn't open subscription options. Check your connection and try again.`,
    }),
};

export const ComputerRequired = {
  name: 'Computer required',
  parameters: galleryParameters,
  render: () =>
    renderPage({ ...shared, stage: `computerRequired`, onThisIsComputer: noop }),
};

export const DownloadHelper = {
  name: 'Download helper',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `download`, onDownload: noop }),
};

export const MacDownloaded = {
  name: 'Downloaded for Mac',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      stage: `download`,
      onDownload: noop,
      platform: `mac`,
      downloaded: true,
    }),
};

export const WindowsDownload = {
  name: 'Windows download warning',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      stage: `download`,
      onDownload: noop,
      platform: `windows`,
      downloaded: true,
    }),
};

export const LaunchHelper = {
  name: 'Open helper',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `launch` }),
};

export const ConnectByUsb = {
  name: 'Connect by USB',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `connect`, code: `420693`, onCopy: noop }),
};

export const CodeCopied = {
  name: 'Code copied',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      stage: `connect`,
      code: `420693`,
      copied: true,
      onCopy: noop,
    }),
};

export const SuperviseInHelper = {
  name: 'Supervise in helper',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `supervise` }),
};

export const CheckingSupervision = {
  name: 'Checking supervision',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `checking` }),
};

export const FinishOnDevice = {
  name: 'Finish on device',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `finishOnDevice` }),
};

export const SetupComplete = {
  name: 'Setup complete',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, stage: `complete` }),
};

export const IpadSetup = {
  name: 'iPad setup',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      stage: `connect`,
      code: `530194`,
      onCopy: noop,
      personName: `Mabel`,
      device: {
        type: `iPad`,
        modelName: `iPad Air (5th generation)`,
        modelIdentifier: `iPad13,16`,
      },
    }),
};
