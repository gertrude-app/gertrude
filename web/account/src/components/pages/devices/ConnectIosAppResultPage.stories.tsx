import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import ConnectIosAppResultPage from './ConnectIosAppResultPage';

type Props = ComponentProps<typeof ConnectIosAppResultPage>;

const noop = (): void => {};
const device: Props[`device`] = {
  type: `iPhone`,
  modelName: `iPhone 15 Pro`,
  modelIdentifier: `iPhone16,1`,
};
const shared = { device, personName: `Jude`, onPrimary: noop, onSecondary: noop };

const renderPage = (props: Props): ReactElement => (
  <StoryScreen>
    <ConnectIosAppResultPage {...props} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Connect iOS App/After assignment',
  component: ConnectIosAppResultPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const BlockerConnected = {
  name: 'Blocker connected',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `blockerConnect` }),
};

export const PodcastsConnected = {
  name: 'Podcasts connected',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `podcasts`, access: `active` }),
};

export const PodcastsTrial = {
  name: 'Podcasts trial',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `podcasts`, access: `trial` }),
};

export const PodcastsEnding = {
  name: 'Podcasts access ending',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      flow: `podcasts`,
      access: `ending`,
      accessEndsAt: `October 12`,
    }),
};

export const PodcastsLapsed = {
  name: 'Podcasts trial ended',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `podcasts`, access: `lapsed` }),
};

export const MusicTrialReady = {
  name: 'Music trial ready',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `music`, access: `trialReady` }),
};

export const MusicTrial = {
  name: 'Music trial active',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `music`, access: `trial` }),
};

export const MusicUnavailable = {
  name: 'Music unavailable',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `music`, access: `unavailable` }),
};

export const SupervisionNeedsPlan = {
  name: 'Supervision needs plan',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `blockerSupervise`, nextStep: `plan` }),
};

export const SupervisionNeedsComputer = {
  name: 'Supervision needs computer',
  parameters: galleryParameters,
  render: () => renderPage({ ...shared, flow: `blockerSupervise`, nextStep: `computer` }),
};

export const IpadConnected = {
  name: 'iPad connected',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      ...shared,
      flow: `music`,
      access: `active`,
      personName: `Mabel`,
      device: {
        type: `iPad`,
        modelName: `iPad Air (5th generation)`,
        modelIdentifier: `iPad13,16`,
      },
    }),
};
