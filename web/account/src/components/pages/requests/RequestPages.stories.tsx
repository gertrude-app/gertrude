import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import SuspensionRequestsPage from './SuspensionRequestsPage';
import UnlockRequestReviewPage from './UnlockRequestReviewPage';
import UnlockRequestsPage from './UnlockRequestsPage';
import SuspensionRequestResponseModal from '#/components/requests/SuspensionRequestResponseModal';
import SuspensionRequestStatusModal from '#/components/requests/SuspensionRequestStatusModal';
import { suspensionRequests } from '#/components/storybook/fixtures';

const noop = (): void => {};
const resolve = async (): Promise<void> => {};
const waitForRender = (): Promise<void> =>
  new Promise((resolveRender) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolveRender())),
  );
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

export const UnlockReview = {
  name: 'Unlock review',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <UnlockRequestReviewPage
        data={{
          personId: `person-jude`,
          personName: `Jude`,
          requests: [
            {
              id: `request-youtube`,
              url: `https://youtube.com/watch?v=secret`,
              domain: `youtube.com`,
              requestComment: `Can I watch a math tutorial?`,
              appName: `Safari`,
              appSlug: `safari`,
              appBundleId: `com.apple.Safari`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:22:00Z`,
            },
            {
              id: `request-youtube-geometry`,
              url: `https://youtube.com/watch?v=geometry`,
              domain: `youtube.com`,
              appName: `Google Chrome`,
              appSlug: `chrome`,
              appBundleId: `com.google.Chrome`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:21:00Z`,
            },
            {
              id: `request-wikipedia`,
              url: `https://en.wikipedia.org/wiki/Algebra`,
              domain: `en.wikipedia.org`,
              appName: `Safari`,
              appSlug: `safari`,
              appBundleId: `com.apple.Safari`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:20:00Z`,
            },
            {
              id: `request-classroom`,
              url: `https://classroom.google.com/u/0/c/assignment`,
              domain: `classroom.google.com`,
              requestComment: `I need the assignment directions.`,
              appName: `Google Chrome`,
              appSlug: `chrome`,
              appBundleId: `com.google.Chrome`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:19:00Z`,
            },
            {
              id: `request-khan-academy`,
              url: `https://cdn.khanacademy.org/videos/quadratic-equations`,
              domain: `cdn.khanacademy.org`,
              appName: `Safari`,
              appSlug: `safari`,
              appBundleId: `com.apple.Safari`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:18:00Z`,
            },
            {
              id: `request-github`,
              url: `https://github.com/school/coding-project`,
              domain: `github.com`,
              appName: `Google Chrome`,
              appSlug: `chrome`,
              appBundleId: `com.google.Chrome`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:17:00Z`,
            },
            {
              id: `request-discord`,
              domain: `discord.com`,
              appName: `Discord`,
              appSlug: `discord`,
              appBundleId: `com.hnc.Discord`,
              appIconHash: `discord`,
              appCategories: [`communication`],
              createdAt: `2026-07-03T14:16:00Z`,
            },
            {
              id: `request-discord-help`,
              domain: `support.example.com`,
              appName: `Discord`,
              appSlug: `discord`,
              appBundleId: `com.hnc.Discord`,
              appIconHash: undefined,
              appCategories: [`communication`],
              createdAt: `2026-07-03T14:15:00Z`,
            },
            {
              id: `request-discord-media`,
              domain: `media.discordapp.net`,
              appName: `Discord`,
              appSlug: `discord`,
              appBundleId: `com.hnc.Discord`,
              appIconHash: undefined,
              appCategories: [`communication`],
              createdAt: `2026-07-03T14:14:00Z`,
            },
            {
              id: `request-discord-gateway`,
              domain: `gateway.discord.gg`,
              appName: `Discord`,
              appSlug: `discord`,
              appBundleId: `com.hnc.Discord`,
              appIconHash: undefined,
              appCategories: [`communication`],
              createdAt: `2026-07-03T14:13:00Z`,
            },
            {
              id: `request-ip`,
              ipAddress: `192.0.2.1`,
              appName: `Safari`,
              appSlug: `safari`,
              appBundleId: `com.apple.Safari`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:12:00Z`,
            },
            {
              id: `request-ip-backup`,
              ipAddress: `203.0.113.42`,
              appName: `Google Chrome`,
              appSlug: `chrome`,
              appBundleId: `com.google.Chrome`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:11:00Z`,
            },
            {
              id: `request-stack-overflow`,
              url: `https://stackoverflow.com/questions/12345`,
              domain: `stackoverflow.com`,
              appName: `Safari`,
              appSlug: `safari`,
              appBundleId: `com.apple.Safari`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:10:00Z`,
            },
            {
              id: `request-chess`,
              url: `https://www.chess.com/puzzles/daily`,
              domain: `www.chess.com`,
              requestComment: `Can I do today's puzzle?`,
              appName: `Safari`,
              appSlug: `safari`,
              appBundleId: `com.apple.Safari`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:09:00Z`,
            },
            {
              id: `request-internet-archive`,
              url: `https://archive.org/details/history-of-flight`,
              domain: `archive.org`,
              appName: `Google Chrome`,
              appSlug: `chrome`,
              appBundleId: `com.google.Chrome`,
              appIconHash: undefined,
              appCategories: [`browser`],
              createdAt: `2026-07-03T14:08:00Z`,
            },
            {
              id: `request-scratch-api`,
              domain: `api.scratch.mit.edu`,
              appName: `Scratch`,
              appSlug: `scratch`,
              appBundleId: `edu.mit.scratch`,
              appIconHash: `scratch`,
              appCategories: [`productivity`],
              createdAt: `2026-07-03T14:07:00Z`,
            },
            {
              id: `request-scratch-project`,
              domain: `scratch.mit.edu`,
              appName: `Scratch`,
              appSlug: `scratch`,
              appBundleId: `edu.mit.scratch`,
              appIconHash: `scratch`,
              appCategories: [`productivity`],
              createdAt: `2026-07-03T14:06:00Z`,
            },
            {
              id: `request-scratch-fonts`,
              domain: `fonts.gstatic.com`,
              appName: `Scratch`,
              appSlug: `scratch`,
              appBundleId: `edu.mit.scratch`,
              appIconHash: `scratch`,
              appCategories: [`productivity`],
              createdAt: `2026-07-03T14:05:00Z`,
            },
            {
              id: `request-minecraft-sessions`,
              domain: `sessionserver.mojang.com`,
              appName: `Minecraft`,
              appSlug: `minecraft`,
              appBundleId: `com.mojang.minecraft`,
              appIconHash: `minecraft`,
              appCategories: [`game`],
              createdAt: `2026-07-03T14:04:00Z`,
            },
            {
              id: `request-minecraft-textures`,
              domain: `textures.minecraft.net`,
              appName: `Minecraft`,
              appSlug: `minecraft`,
              appBundleId: `com.mojang.minecraft`,
              appIconHash: undefined,
              appCategories: [`game`],
              createdAt: `2026-07-03T14:03:00Z`,
            },
            {
              id: `request-study-helper-api`,
              domain: `api.studybuddy.dev`,
              appName: undefined,
              appSlug: undefined,
              appBundleId: `com.example.study-helper`,
              appIconHash: undefined,
              appCategories: [`education`],
              createdAt: `2026-07-03T14:02:00Z`,
            },
            {
              id: `request-study-helper-updates`,
              domain: `updates.example.net`,
              appName: undefined,
              appSlug: undefined,
              appBundleId: `com.example.study-helper`,
              appIconHash: undefined,
              appCategories: [`education`],
              createdAt: `2026-07-03T14:01:00Z`,
            },
          ],
          keychains: [
            { id: `keychain-default`, name: `Jude's Keychain`, numKeys: 12 },
            { id: `keychain-school`, name: `School`, numKeys: 8 },
          ],
        }}
        saving={false}
        appIconUrl={(hash) => `/example-app-icons/${hash}.webp`}
        onSubmit={noop}
        onRefresh={noop}
      />
    </StoryScreen>
  ),
};
