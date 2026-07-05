import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import RequestsShellPage from './RequestsShellPage';
import SuspensionRequestsPage from './SuspensionRequestsPage';
import UnlockRequestsPage from './UnlockRequestsPage';
import {
  keychains,
  suspensionRequests,
  unlockRequests,
} from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Pages/Requests',
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Unlock = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <RequestsShellPage
        selectedHref="/requests/unlock"
        unlockRequestsHref="/requests/unlock"
        suspensionRequestsHref="/requests/suspension"
        unlockRequestCount={unlockRequests.length}
        suspensionRequestCount={suspensionRequests.length}
      >
        <UnlockRequestsPage
          requests={unlockRequests}
          keychainOptions={keychains.map((keychain) => ({
            id: keychain.id,
            name: keychain.name,
          }))}
          onDeny={noop}
          onAllow={noop}
        />
      </RequestsShellPage>
    </StoryScreen>
  ),
};

export const Suspension = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <RequestsShellPage
        selectedHref="/requests/suspension"
        unlockRequestsHref="/requests/unlock"
        suspensionRequestsHref="/requests/suspension"
        unlockRequestCount={unlockRequests.length}
        suspensionRequestCount={suspensionRequests.length}
      >
        <SuspensionRequestsPage
          requests={suspensionRequests}
          onDeny={noop}
          onGrant={noop}
        />
      </RequestsShellPage>
    </StoryScreen>
  ),
};
