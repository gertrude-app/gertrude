import {
  StoryScreen,
  galleryParameters,
  useSyncedStoryState,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React, { type ComponentProps, type ReactElement } from 'react';
import type { UnlockReviewEntry } from '#/lib/unlockRequests';
import SuspensionRequestsPage from './SuspensionRequestsPage';
import { UnlockRequestReviewEditor } from './UnlockRequestReviewPage';
import UnlockRequestsPage from './UnlockRequestsPage';
import SuspensionRequestResponseModal from '#/components/requests/SuspensionRequestResponseModal';
import SuspensionRequestStatusModal from '#/components/requests/SuspensionRequestStatusModal';
import {
  keychains,
  suspensionRequests,
  unlockRequest,
} from '#/components/storybook/fixtures';
import { unlockReviewDraft, waitForRender } from '#/components/storybook/unlockReview';
import { updateGroupKeyAddressMatch } from '#/lib/unlockRequests';

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

const scratchApp = {
  appName: `Scratch`,
  appSlug: `scratch`,
  appBundleId: `edu.mit.scratch`,
  appIconHash: `scratch`,
  appCategories: [`productivity`],
};

const unknownApp = {
  appName: undefined,
  appSlug: undefined,
  appBundleId: `com.example.study-helper`,
  appCategories: [`education`],
};

const chromeApp = {
  appName: `Google Chrome`,
  appSlug: `chrome`,
  appBundleId: `com.google.Chrome`,
  appCategories: [`browser`],
};

const unlockReviewPerson = {
  personId: `person-jude`,
  personName: `Jude`,
  keychains: keychains.slice(0, 2),
};

const unlockReviewProps = {
  saving: false,
  appIconUrl: (hash: string) => `/example-app-icons/${hash}.webp`,
  onSubmit: noop,
  onRefresh: noop,
};

const UnlockReviewStory: React.FC<{
  initialEntries: UnlockReviewEntry[];
  saving?: boolean;
}> = ({ initialEntries, saving = false }) => {
  const [entries, setEntries] = useSyncedStoryState(initialEntries);
  return (
    <StoryScreen>
      <UnlockRequestReviewEditor
        {...unlockReviewProps}
        data={{
          ...unlockReviewPerson,
          requests: initialEntries.flatMap((entry) =>
            (entry.kind === `web` ? [entry.group] : entry.groups).flatMap(
              (group) => group.requests,
            ),
          ),
        }}
        entries={entries}
        setEntries={setEntries}
        saving={saving}
      />
    </StoryScreen>
  );
};

export const UnlockReview = {
  name: 'Unlock review',
  parameters: galleryParameters,
  render: () => (
    <UnlockReviewStory
      initialEntries={unlockReviewDraft(
        [
          unlockRequest(`docs.example.com`, { requestComment: `For my homework.` }),
          unlockRequest(`docs.example.com`, chromeApp),
          unlockRequest(`lesson.docs.example.com`),
          unlockRequest(`school.example.com`),
          unlockRequest(`khanacademy.org`),
          unlockRequest(`youtube.com`, {
            requestComment: `Can I watch a math tutorial?`,
          }),
          unlockRequest(`support.example.com`, {
            appName: `Discord`,
            appSlug: `discord`,
            appBundleId: `com.hnc.Discord`,
            appIconHash: `discord`,
            appCategories: [`communication`],
          }),
          unlockRequest(`other.example.org`, { appCategories: [] }),
          unlockRequest(`class.example.org`),
          unlockRequest(`class.example.org`, chromeApp),
          unlockRequest(`api.studybuddy.dev`, unknownApp),
        ],
        (group) => {
          if ([`docs.example.com`, `other.example.org`].includes(group.target)) {
            return { ...updateGroupKeyAddressMatch(group, `parent`), decision: `allow` };
          }
          return group.target === `school.example.com`
            ? { ...group, decision: `allow`, comment: `For homework.` }
            : group;
        },
      ).map((entry) =>
        entry.kind === `app` && entry.name === `Unknown app`
          ? { ...entry, choice: `unrestricted` }
          : entry,
      )}
    />
  ),
};

export const UnlockReviewPermissionIssues = {
  name: 'Unlock review exceptions',
  parameters: galleryParameters,
  render: () => (
    <UnlockReviewStory
      initialEntries={unlockReviewDraft(
        [
          unlockRequest(`docs.example.com`),
          unlockRequest(`school.example.com`),
          unlockRequest(`docs.example.net`),
          unlockRequest(`school.example.net`),
          unlockRequest(`expired.study.test`),
          unlockRequest(`api.scratch.mit.edu`, scratchApp),
        ],
        (group) => {
          switch (group.target) {
            case `school.example.com`:
              return { ...group, decision: `deny` };
            case `docs.example.net`:
              return {
                ...updateGroupKeyAddressMatch(group, `parent`),
                decision: `allow`,
                expiration: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
              };
            case `school.example.net`:
              return { ...group, decision: `allow` };
            case `expired.study.test`:
              return { ...group, decision: `allow`, expiration: `2020-01-15T12:00:00Z` };
            case `api.scratch.mit.edu`:
              return {
                ...group,
                decision: `allow`,
                key: {
                  type: `domain`,
                  domain: group.target,
                  scope: { type: `webBrowsers` },
                },
              };
            default:
              return {
                ...updateGroupKeyAddressMatch(group, `parent`),
                decision: `allow`,
              };
          }
        },
      )}
    />
  ),
};

export const UnlockReviewSaving = {
  name: 'Unlock review saving',
  parameters: galleryParameters,
  render: () => (
    <UnlockReviewStory
      initialEntries={unlockReviewDraft([unlockRequest(`docs.example.com`)], (group) => ({
        ...group,
        decision: `allow`,
      }))}
      saving
    />
  ),
};
