import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import SecurityEventsPreviewCard from './SecurityEventsPreviewCard';
import SuspensionRequestCard from './SuspensionRequestCard';
import SuspensionRequestsPreviewCard from './SuspensionRequestsPreviewCard';
import UnlockRequestCard from './UnlockRequestCard';
import UnlockRequestsPreviewCard from './UnlockRequestsPreviewCard';
import {
  keychains,
  securityEvents,
  suspensionRequests,
} from '#/components/storybook/fixtures';
import { buildUnlockReview } from '#/lib/unlockRequests';

const noop = (): void => {};
const responseHrefForRequest = (id: string): string => `/requests/suspension/${id}`;
const unlockSummary = {
  totalCount: 4,
  people: [
    {
      id: `person-jude`,
      name: `Jude`,
      pendingCount: 4,
      targets: [`youtube.com`, `school.example.com`, `scratch.mit.edu`, `wikipedia.org`],
    },
  ],
};
const unlockReview = buildUnlockReview(
  [
    {
      id: `request-youtube`,
      domain: `youtube.com`,
      requestComment: `Can I watch a tutorial?`,
      appName: `Safari`,
      appSlug: `safari`,
      appBundleId: `com.apple.Safari`,
      appCategories: [`browser`],
      createdAt: `2026-07-03T14:05:00Z`,
    },
  ],
  keychains[0]!.id,
)[0]!;

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
          summary={unlockSummary}
          viewAllHref="/requests/unlock"
          reviewHrefForPerson={(personId) => `/requests/unlock/${personId}`}
        />
        <SecurityEventsPreviewCard
          state={{ status: `success`, data: securityEvents }}
          onRefresh={noop}
          viewAllHref="/security-events"
        />
      </StorySection>
      <StorySection
        title="Empty preview cards"
        contentClassName="grid grid-cols-1 gap-6 @3xl/main:grid-cols-3"
      >
        <SuspensionRequestsPreviewCard
          suspensionRequests={[]}
          onRefresh={noop}
          responseHrefForRequest={responseHrefForRequest}
        />
        <SecurityEventsPreviewCard
          state={{ status: `success`, data: [] }}
          onRefresh={noop}
        />
      </StorySection>
      <StorySection
        title="Request cards"
        contentClassName="grid grid-cols-1 gap-4 @3xl/main:grid-cols-2"
      >
        <SuspensionRequestCard
          request={suspensionRequests[0]!}
          responseHref={responseHrefForRequest(suspensionRequests[0]!.id)}
        />
        {unlockReview.kind === `web` && (
          <UnlockRequestCard
            group={unlockReview.group}
            keychainOptions={keychains.map((keychain) => ({
              id: keychain.id,
              name: keychain.name,
            }))}
            onChange={noop}
          />
        )}
      </StorySection>
    </StoryCanvas>
  ),
};
