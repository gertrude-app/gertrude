import {
  StoryCanvas,
  StoryScreen,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import SecurityEventsPreviewCard from './SecurityEventsPreviewCard';
import SuspensionRequestCard from './SuspensionRequestCard';
import SuspensionRequestsPreviewCard from './SuspensionRequestsPreviewCard';
import UnlockRequestCard from './UnlockRequestCard';
import UnlockRequestResponsePanel from './UnlockRequestResponsePanel';
import UnlockRequestsPreviewCard from './UnlockRequestsPreviewCard';
import {
  keychains,
  securityEvents,
  suspensionRequests,
  unlockRequests,
} from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Components/Requests/Cards and Panels',
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Cards = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-5xl">
      <StorySection
        title="Preview cards"
        contentClassName="grid grid-cols-1 gap-6 @3xl/main:grid-cols-3"
      >
        <SuspensionRequestsPreviewCard
          suspensionRequests={suspensionRequests}
          viewAllHref="/requests/suspension"
        />
        <UnlockRequestsPreviewCard
          unlockRequests={unlockRequests}
          viewAllHref="/requests/unlock"
        />
        <SecurityEventsPreviewCard
          securityEvents={securityEvents}
          viewAllHref="/events"
        />
      </StorySection>
      <StorySection
        title="Request cards"
        contentClassName="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2"
      >
        <SuspensionRequestCard
          request={suspensionRequests[0]!}
          onDeny={noop}
          onGrant={noop}
        />
        <UnlockRequestCard
          request={unlockRequests[0]!}
          keychainOptions={keychains.map((keychain) => ({
            id: keychain.id,
            name: keychain.name,
          }))}
          onDeny={noop}
          onAllow={noop}
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const UnlockResponsePanel = {
  name: 'Unlock response panel',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <div className="h-screen bg-white pt-8">
        <UnlockRequestResponsePanel
          domains={unlockRequests[0]!.domains}
          keychainOptions={keychains.map((keychain) => ({
            id: keychain.id,
            name: keychain.name,
          }))}
          onDenyAll={noop}
          onSave={noop}
        />
      </div>
    </StoryScreen>
  ),
};
