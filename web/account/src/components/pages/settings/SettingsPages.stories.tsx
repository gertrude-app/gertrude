import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import NotificationSettingsPage from './NotificationSettingsPage';
import SettingsShellPage from './SettingsShellPage';
import { notificationMethods, notifications } from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Pages/Settings',
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Notifications = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <SettingsShellPage
        email="parent@example.com"
        selectedHref="/settings/notifications"
        notificationsHref="/settings/notifications"
        billingHref="/settings/billing"
        onChangePassword={noop}
      >
        <NotificationSettingsPage
          notificationMethods={notificationMethods}
          notifications={notifications}
          onCreateMethod={noop}
          onDeleteMethod={noop}
          onCreateNotification={noop}
          onUpdateNotification={noop}
          onDeleteNotification={noop}
        />
      </SettingsShellPage>
    </StoryScreen>
  ),
};
