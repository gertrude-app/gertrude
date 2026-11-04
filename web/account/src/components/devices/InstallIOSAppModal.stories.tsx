import { StoryCanvas, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { IOSSetupApp } from '#/components/onboarding/setupApps';
import type { ComponentProps } from 'react';
import InstallIOSAppModal from './InstallIOSAppModal';

const noop = (): void => {};

const meta = {
  title: 'Account/Devices/Install iOS App Modal',
  component: InstallIOSAppModal,
  parameters: { layout: 'fullscreen' },
};

export default meta;

const renderModal = (
  app: IOSSetupApp,
  props: Partial<ComponentProps<typeof InstallIOSAppModal>> = {},
) => (
  <StoryCanvas>
    <InstallIOSAppModal
      open
      onOpenChange={noop}
      app={app}
      personName="Jimmy"
      shareMethod="share"
      onShareLink={noop}
      {...props}
    />
  </StoryCanvas>
);

export const Music = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => renderModal(`music`),
};

export const Blocker = {
  parameters: galleryParameters,
  render: () => renderModal(`blocker`),
};

export const Podcasts = {
  parameters: galleryParameters,
  render: () => renderModal(`podcasts`),
};

export const CopyLink = {
  name: 'Copy link (no share sheet)',
  parameters: galleryParameters,
  render: () => renderModal(`music`, { shareMethod: `copy` }),
};

export const LinkCopied = {
  name: 'Link copied',
  parameters: galleryParameters,
  render: () => renderModal(`music`, { shareMethod: `copy`, copied: true }),
};

export const SeveralPeople = {
  name: 'Several people',
  parameters: galleryParameters,
  render: () => renderModal(`blocker`, { personName: undefined }),
};
