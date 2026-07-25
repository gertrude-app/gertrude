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
const responseHrefForRequest = (id: string): string => `/requests/suspension/${id}`;
const expandedUnlockDomain = unlockRequests[0]!.domains[0]!;

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
          onRefresh={noop}
          viewAllHref="/requests/suspension"
          responseHrefForRequest={responseHrefForRequest}
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
      <StorySection title="Empty preview card">
        <div className="w-72">
          <SuspensionRequestsPreviewCard
            suspensionRequests={[]}
            onRefresh={noop}
            responseHrefForRequest={responseHrefForRequest}
          />
        </div>
      </StorySection>
      <StorySection
        title="Request cards"
        contentClassName="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2"
      >
        <SuspensionRequestCard
          request={suspensionRequests[0]!}
          responseHref={responseHrefForRequest(suspensionRequests[0]!.id)}
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
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen>
      <div className="h-screen bg-white pt-8">
        <UnlockRequestResponsePanel
          domains={unlockRequests[0]!.domains}
          defaultExpandedDomains={[expandedUnlockDomain]}
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
