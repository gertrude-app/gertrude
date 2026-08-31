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
const createPending = async (): Promise<{ methodId: string; ntfyTopic: string }> => ({
  methodId: `method-preview`,
  ntfyTopic: `gertrude-family-alerts-8k4tq9`,
});
const confirm = async (): Promise<void> => {};
const save = async (): Promise<void> => {};

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
            deletable={index === 0}
            deleteBlockedReason={index === 0 ? undefined : `This method is in use.`}
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
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryCanvas>
      <AddNotificationMethodSlideOver
        open
        onOpenChange={noop}
        onCreatePending={createPending}
        onConfirm={confirm}
        onComplete={noop}
      />
    </StoryCanvas>
  ),
};

export const AddMethodVerification = {
  name: 'Add method verification slide-over',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <StoryCanvas>
      <AddNotificationMethodSlideOver
        open
        onOpenChange={noop}
        onCreatePending={createPending}
        onConfirm={confirm}
        onComplete={noop}
        defaultState={{
          methodType: `email`,
          flowState: `codeSent`,
          pendingMethodId: `method-preview`,
          emailAddress: `parent@example.com`,
          confirmationCode: `123456`,
        }}
      />
    </StoryCanvas>
  ),
};

export const AddMethodNtfySuccess = {
  name: 'Add method ntfy success slide-over',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <StoryCanvas>
      <AddNotificationMethodSlideOver
        open
        onOpenChange={noop}
        onCreatePending={createPending}
        onConfirm={confirm}
        onComplete={noop}
        defaultState={{
          methodType: `ntfy`,
          flowState: `ntfyCreated`,
          pendingMethodId: `method-preview`,
        }}
      />
    </StoryCanvas>
  ),
};

export const EditNotification = {
  name: 'Edit notification slide-over',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryCanvas>
      <NotificationEditorSlideOver
        open
        notification={notifications[1]!}
        methods={notificationMethods}
        onOpenChange={noop}
        onSave={save}
      />
    </StoryCanvas>
  ),
};
