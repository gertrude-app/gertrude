import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React, { type ComponentProps, type ReactElement } from 'react';
import type { UnlockReviewEntry } from '#/lib/unlockRequests';
import type { GetPersonUnlockRequests } from '@shared/pairql/src/account';
import SuspensionRequestsPage from './SuspensionRequestsPage';
import UnlockRequestReviewPage from './UnlockRequestReviewPage';
import UnlockRequestsPage from './UnlockRequestsPage';
import SuspensionRequestResponseModal from '#/components/requests/SuspensionRequestResponseModal';
import SuspensionRequestStatusModal from '#/components/requests/SuspensionRequestStatusModal';
import {
  keychains,
  suspensionRequests,
  unlockRequest,
} from '#/components/storybook/fixtures';
import { unlockReviewDraft, waitForRender } from '#/components/storybook/unlockReview';
import { buildUnlockReview, updateGroupKeyAddressMatch } from '#/lib/unlockRequests';

const noop = (): void => {};
const resolve = async (): Promise<void> => {};
const responseHrefForRequest = (id: string): string => `/requests/suspension/${id}`;

type SuspensionRequestsPageProps = ComponentProps<typeof SuspensionRequestsPage>;

const defaultSuspensionProps: SuspensionRequestsPageProps = {
  state: { status: `success`, data: suspensionRequests },
  onRefresh: noop,
  responseHrefForRequest,
};

const renderSuspensionPage = (
  overrides: Partial<SuspensionRequestsPageProps> = {},
  modal?: ReactElement,
): ReactElement => (
  <StoryScreen>
    <SuspensionRequestsPage {...defaultSuspensionProps} {...overrides} />
    {modal}
  </StoryScreen>
);

const responseModal = (
  request = suspensionRequests[0]!,
  responding?: `deny` | `grant`,
): ReactElement => (
  <SuspensionRequestResponseModal
    request={request}
    open
    responding={responding}
    onOpenChange={noop}
    onDeny={resolve}
    onGrant={resolve}
  />
);

const meta = {
  title: 'Account/Pages/Requests',
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Suspension = {
  parameters: galleryParameters,
  render: () => renderSuspensionPage(),
};

export const SuspensionEmpty = {
  name: 'Suspension empty',
  parameters: galleryParameters,
  render: () => renderSuspensionPage({ state: { status: `success`, data: [] } }),
};

export const SuspensionEmptyRefreshing = {
  name: 'Suspension empty refreshing',
  parameters: galleryParameters,
  render: () =>
    renderSuspensionPage({
      state: { status: `success`, data: [] },
      refreshing: true,
    }),
};

export const SuspensionLoading = {
  name: 'Suspension loading',
  parameters: galleryParameters,
  render: () => renderSuspensionPage({ state: { status: `loading` } }),
};

export const SuspensionError = {
  name: 'Suspension error',
  parameters: galleryParameters,
  render: () =>
    renderSuspensionPage({
      state: {
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: noop,
      },
    }),
};

export const SuspensionGranting = {
  name: 'Suspension granting',
  parameters: galleryParameters,
  render: () => renderSuspensionPage({}, responseModal(suspensionRequests[1]!, `grant`)),
};

export const SuspensionResponseDialog = {
  name: 'Suspension response dialog',
  parameters: galleryParameters,
  render: () => renderSuspensionPage({}, responseModal()),
};

export const SuspensionUnavailable = {
  name: 'Suspension request unavailable',
  parameters: galleryParameters,
  render: () =>
    renderSuspensionPage(
      {},
      <SuspensionRequestStatusModal
        title="Request no longer pending"
        description="This request may have already been answered or may be more than two hours old."
        onClose={noop}
      />,
    ),
};

export const SuspensionMonitoringOptions = {
  name: 'Suspension monitoring options',
  parameters: galleryParameters,
  render: () => renderSuspensionPage({}, responseModal()),
  play: async ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const monitoringSelect = Array.from(
      canvasElement.ownerDocument.querySelectorAll<HTMLButtonElement>(`button`),
    ).find((button) => button.textContent?.includes(`No extra monitoring`));

    if (!monitoringSelect) {
      throw new Error(`Couldn't find monitoring select`);
    }

    monitoringSelect.click();
    await waitForRender();
  },
};

export const SuspensionCustomDurationDialog = {
  name: 'Suspension custom duration response',
  parameters: galleryParameters,
  render: () => {
    const request = {
      ...suspensionRequests[0]!,
      requestedDurationInSeconds: 17 * 60,
      duration: `17 minutes`,
    };
    return renderSuspensionPage(
      { state: { status: `success`, data: [request, suspensionRequests[1]!] } },
      responseModal(request),
    );
  },
};

const unlockSummary = {
  totalCount: 7,
  people: [
    {
      id: `person-jude`,
      name: `Jude`,
      pendingCount: 5,
      targets: [
        `youtube.com`,
        `school.example.com`,
        `scratch.mit.edu`,
        `wikipedia.org`,
        `khanacademy.org`,
      ],
    },
    {
      id: `person-lucy`,
      name: `Lucy`,
      pendingCount: 2,
      targets: [`192.0.2.1`, `minecraft.net`],
    },
  ],
};

export const Unlock = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <UnlockRequestsPage
        state={{ status: `success`, data: unlockSummary }}
        suspensionRequestCount={suspensionRequests.length}
        onRefresh={noop}
        reviewHrefForPerson={(personId) => `/requests/unlock/${personId}`}
      />
    </StoryScreen>
  ),
};

const reviewKeychains: GetPersonUnlockRequests.Output[`keychains`] = [
  { ...keychains[0]!, name: `Jude's keychain`, otherPeople: [] },
  {
    ...keychains[1]!,
    name: `Weekend games`,
    otherPeople: [`Lucy`],
    schedule: {
      type: `active`,
      days: {
        sunday: true,
        monday: false,
        tuesday: false,
        wednesday: false,
        thursday: false,
        friday: false,
        saturday: true,
      },
      startTime: { hour: 9, minute: 0 },
      endTime: { hour: 18, minute: 0 },
    },
  },
];

const reviewRequests = [
  unlockRequest(`docs.example.com`, { requestComment: `For my homework.` }),
  unlockRequest(`www.docs.example.com`, {
    requestComment: `The same lesson in Chrome.`,
    appSlug: `chrome`,
  }),
  unlockRequest(`school.example.com`),
  unlockRequest(`lesson.docs.example.com`),
  unlockRequest(`youtube.com`, { requestComment: `Can I watch a math tutorial?` }),
];

const UnlockReviewStory: React.FC<{
  requests?: GetPersonUnlockRequests.Output[`requests`];
  initialEntries?: UnlockReviewEntry[];
  saving?: boolean;
}> = ({ requests: initialRequests = reviewRequests, initialEntries, saving = false }) => {
  const [requests, setRequests] = React.useState(initialRequests);
  const [pending, setPending] = React.useState(false);
  return (
    <StoryScreen>
      <UnlockRequestReviewPage
        initialEntries={initialEntries}
        data={{
          personName: `Jude`,
          requests,
          keychains: reviewKeychains,
          defaultKeychainId: reviewKeychains[0]!.id,
        }}
        saving={saving || pending}
        appIconUrl={(hash) => `/example-app-icons/${hash}.webp`}
        onRefresh={() => setRequests((current) => [...current])}
        onSubmit={async (decisions) => {
          setPending(true);
          await new Promise((resolve) => setTimeout(resolve, 600));
          setPending(false);
          const ids = new Set(decisions.flatMap((decision) => decision.requestIds));
          setRequests((current) => current.filter((request) => !ids.has(request.id)));
        }}
      />
    </StoryScreen>
  );
};

export const UnlockReview = {
  name: 'Unlock review — start here',
  parameters: galleryParameters,
  render: () => <UnlockReviewStory />,
};

const overlapRequests = [
  unlockRequest(`docs.example.com`),
  unlockRequest(`school.example.com`),
  unlockRequest(`lesson.docs.example.com`),
];
export const UnlockReviewExplicitApprovals = {
  name: 'Unlock review — explicit approvals and schedules',
  parameters: galleryParameters,
  render: () => (
    <UnlockReviewStory
      requests={overlapRequests}
      initialEntries={unlockReviewDraft(overlapRequests, (group) =>
        group.target === `docs.example.com`
          ? {
              ...updateGroupKeyAddressMatch(group, `parent`),
              decision: `allow`,
              keychainId: reviewKeychains[1]!.id,
            }
          : group.target === `school.example.com`
            ? {
                ...group,
                decision: `allow`,
                keychainId: reviewKeychains[0]!.id,
                comment: `Keep this school permission separate.`,
                expiration: `2099-01-01T18:00:00Z`,
              }
            : group,
      )}
    />
  ),
};

export const UnlockReviewPermissionIssues = {
  name: 'Unlock review — denial conflict',
  parameters: galleryParameters,
  render: () => (
    <UnlockReviewStory
      requests={overlapRequests}
      initialEntries={unlockReviewDraft(overlapRequests, (group) =>
        group.target === `docs.example.com`
          ? { ...updateGroupKeyAddressMatch(group, `parent`), decision: `allow` }
          : group.target === `school.example.com`
            ? { ...group, decision: `deny` }
            : group,
      )}
    />
  ),
};

const appRequests = [
  unlockRequest(`api.scratch.mit.edu`, {
    appName: `Scratch`,
    appSlug: `scratch`,
    appBundleId: `edu.mit.scratch`,
    appCategories: [`productivity`],
    appIconHash: `scratch`,
  }),
  unlockRequest(`assets.scratch.mit.edu`, {
    appName: `Scratch`,
    appSlug: `scratch`,
    appBundleId: `edu.mit.scratch`,
    appCategories: [`productivity`],
    appIconHash: `scratch`,
  }),
  unlockRequest(`api.studybuddy.dev`, {
    appName: undefined,
    appSlug: undefined,
    appBundleId: `com.example.study-helper`,
    appCategories: [],
  }),
  unlockRequest(`192.0.2.1`, { domain: undefined, ipAddress: `192.0.2.1` }),
];
export const UnlockReviewApps = {
  name: 'Unlock review — apps and direct IP addresses',
  parameters: galleryParameters,
  render: () => <UnlockReviewStory requests={appRequests} />,
};

export const UnlockReviewSaving = {
  name: 'Unlock review — saving',
  parameters: galleryParameters,
  render: () => (
    <UnlockReviewStory
      requests={[reviewRequests[0]!]}
      initialEntries={buildUnlockReview([reviewRequests[0]!], reviewKeychains[0]!.id).map(
        (entry) =>
          entry.kind === `web`
            ? { ...entry, group: { ...entry.group, decision: `allow` } }
            : entry,
      )}
      saving
    />
  ),
};
