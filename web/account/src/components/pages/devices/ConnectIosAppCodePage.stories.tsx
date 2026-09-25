import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import ConnectIosAppCodePage from './ConnectIosAppCodePage';

type Props = ComponentProps<typeof ConnectIosAppCodePage>;

const noop = (): void => {};
const blocker = {
  appName: `Gertrude Blocker`,
  appIconUrl: `/gertrude-app-icons/blocker.webp`,
};

const renderPage = (props: Props): ReactElement => (
  <StoryScreen>
    <ConnectIosAppCodePage {...props} />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Connect iOS App/Code and recovery',
  component: ConnectIosAppCodePage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const CheckingCode = {
  name: 'Checking code',
  parameters: galleryParameters,
  render: () => renderPage({ ...blocker, state: `checking` }),
};

export const InvalidCode = {
  name: 'Code not found',
  parameters: galleryParameters,
  render: () => renderPage({ ...blocker, state: `invalid`, onBack: noop }),
};

export const ExpiredCode = {
  name: 'Code expired',
  parameters: galleryParameters,
  render: () => renderPage({ ...blocker, state: `expired`, onBack: noop }),
};

export const CheckFailed = {
  name: 'Could not check code',
  parameters: galleryParameters,
  render: () => renderPage({ ...blocker, state: `error`, onBack: noop, onRetry: noop }),
};

export const ResumingSupervision = {
  name: 'Resuming supervision',
  parameters: galleryParameters,
  render: () => renderPage({ ...blocker, state: `resuming`, modelName: `iPhone 15 Pro` }),
};

export const PodcastsCodeExpired = {
  name: 'Podcasts code expired',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      appName: `Gertrude Podcasts`,
      appIconUrl: `/gertrude-app-icons/podcasts.webp`,
      state: `expired`,
      onBack: noop,
    }),
};

export const MusicCodeNotFound = {
  name: 'Music code not found',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      appName: `Gertrude Music`,
      appIconUrl: `/gertrude-app-icons/music.webp`,
      state: `invalid`,
      onBack: noop,
    }),
};
