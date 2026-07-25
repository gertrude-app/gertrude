import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { ComponentProps, ReactElement } from 'react';
import SuspensionRequestsPage from './SuspensionRequestsPage';
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

export const Unlock = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <UnlockRequestsPage suspensionRequestCount={suspensionRequests.length} />
    </StoryScreen>
  ),
};
