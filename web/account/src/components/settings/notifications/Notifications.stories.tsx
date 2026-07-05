import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import AddNotificationMethodSlideOver from './AddNotificationMethodSlideOver';
import NotificationCard from './NotificationCard';
import NotificationEditorSlideOver from './NotificationEditorSlideOver';
import NotificationMethodChip from './NotificationMethodChip';
import { notificationMethods, notifications } from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Components/Settings/Notifications',
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const MethodsAndNotifications = {
  name: 'Methods and notifications',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-5xl">
      <StorySection title="Methods">
        {notificationMethods.map((method, index) => (
          <NotificationMethodChip
            key={method.id}
            method={method}
            notificationCount={index}
            onDelete={noop}
          />
        ))}
      </StorySection>
      <StorySection
        title="Notifications"
        contentClassName="grid grid-cols-1 gap-3 @3xl/main:grid-cols-2"
      >
        {notifications.map((notification) => (
          <NotificationCard
            key={notification.id}
            notification={notification}
            onEdit={noop}
            onDelete={noop}
          />
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};

export const AddMethod = {
  name: 'Add method slide-over',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <AddNotificationMethodSlideOver open onOpenChange={noop} onComplete={noop} />
    </StoryCanvas>
  ),
};

export const EditNotification = {
  name: 'Edit notification slide-over',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <NotificationEditorSlideOver
        open
        notification={notifications[0]!}
        methods={notificationMethods}
        onOpenChange={noop}
        onSave={noop}
      />
    </StoryCanvas>
  ),
};
