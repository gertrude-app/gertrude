import { Button, Card, EmptyState, HStack, Text, Toggle, VStack } from '@gertrude/ui';
import { BellRingIcon, PlusIcon } from 'lucide-react';
import React from 'react';
import type { Notification, NotificationMethod } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import AddNotificationMethodSlideOver, {
  type NotificationMethodDraft,
  type PendingNotificationMethod,
} from '#/components/settings/notifications/AddNotificationMethodSlideOver';
import NotificationCard from '#/components/settings/notifications/NotificationCard';
import NotificationEditorSlideOver, {
  type NotificationDraft,
} from '#/components/settings/notifications/NotificationEditorSlideOver';
import NotificationMethodChip from '#/components/settings/notifications/NotificationMethodChip';

type ActiveNotificationEditor =
  { type: `new`; methodId?: string } | { type: `edit`; id: string } | null;

interface Props {
  accountEmail: string;
  dailyReviewEmail: boolean;
  hasMacScreenshotUsers: boolean;
  settingDailyReviewEmail: boolean;
  notificationMethods: NotificationMethod[];
  notifications: Notification[];
  onSetDailyReviewEmail: (enabled: boolean) => void;
  onCreatePendingMethod: (
    draft: NotificationMethodDraft,
  ) => Promise<PendingNotificationMethod>;
  onConfirmPendingMethod: (methodId: string, code: number) => Promise<void>;
  onDeleteMethod: (id: string) => void;
  onCreateNotification: (draft: NotificationDraft) => Promise<void>;
  onUpdateNotification: (id: string, draft: NotificationDraft) => Promise<void>;
  onDeleteNotification: (id: string) => void;
}

const NotificationSettingsPage: React.FC<Props> = ({
  accountEmail,
  dailyReviewEmail,
  hasMacScreenshotUsers,
  settingDailyReviewEmail,
  notificationMethods,
  notifications,
  onSetDailyReviewEmail,
  onCreatePendingMethod,
  onConfirmPendingMethod,
  onDeleteMethod,
  onCreateNotification,
  onUpdateNotification,
  onDeleteNotification,
}) => {
  const [addMethodOpen, setAddMethodOpen] = React.useState(false);
  const [activeEditor, setActiveEditor] = React.useState<ActiveNotificationEditor>(null);
  const activeNotification =
    activeEditor?.type === `edit`
      ? notifications.find((notification) => notification.id === activeEditor.id)
      : undefined;
  const editorOpen = activeEditor?.type === `new` || activeNotification !== undefined;

  const openNewNotificationEditor = (): void => {
    if (notificationMethods.length === 0) {
      setAddMethodOpen(true);
      return;
    }

    setActiveEditor({ type: `new` });
  };

  const saveActiveNotification = async (draft: NotificationDraft): Promise<void> => {
    if (!activeEditor) {
      return;
    }

    if (activeEditor.type === `edit`) {
      await onUpdateNotification(activeEditor.id, draft);
    } else {
      await onCreateNotification(draft);
    }

    setActiveEditor(null);
  };

  const deleteNotificationMethod = (id: string): void => {
    onDeleteMethod(id);
    setActiveEditor((current) => {
      if (current?.type !== `edit`) {
        return current;
      }

      const editingNotification = notifications.find(
        (notification) => notification.id === current.id,
      );

      return editingNotification?.methodId === id ? null : current;
    });
  };

  return (
    <>
      <VStack gap={4} className="mt-4">
        {hasMacScreenshotUsers && (
          <CardContainer
            heading="Email reminders"
            subheading="A nudge to review recent Mac activity when there is something new to see."
          >
            <Card padding={4} className="mt-4">
              <HStack justify="between" align="center" gap={4}>
                <VStack gap={0.5}>
                  <Text as="h3" variant="bodyStrong">
                    Daily review reminder
                  </Text>
                  <Text as="p" variant="bodyMuted">
                    Send an email on days when protected Macs capture screenshots.
                  </Text>
                </VStack>
                <Toggle
                  checked={dailyReviewEmail}
                  setChecked={onSetDailyReviewEmail}
                  disabled={settingDailyReviewEmail}
                  ariaLabel="Daily review reminder"
                />
              </HStack>
            </Card>
          </CardContainer>
        )}
        <CardContainer
          heading="Methods"
          subheading="Verified ways that Gertrude can notify you for child requests and events."
          buttons={
            <Button type="button" onClick={() => setAddMethodOpen(true)} icon={PlusIcon}>
              Add Method
            </Button>
          }
        >
          <HStack wrap gap={2} className="mt-4">
            {notificationMethods.map((method) => {
              const notificationCount = notifications.filter(
                (notification) => notification.methodId === method.id,
              ).length;
              const isAccountEmail =
                method.type === `email` &&
                method.emailAddress.toLowerCase() === accountEmail.toLowerCase();
              const deletable = notificationCount === 0 && !isAccountEmail;
              const deleteBlockedReason = isAccountEmail
                ? `Your account email method cannot be deleted.`
                : `Delete notifications using this method first.`;

              return (
                <NotificationMethodChip
                  key={method.id}
                  method={method}
                  deletable={deletable}
                  deleteBlockedReason={deleteBlockedReason}
                  onDelete={() => deleteNotificationMethod(method.id)}
                />
              );
            })}
          </HStack>
        </CardContainer>
        <CardContainer
          heading="Notifications"
          subheading="Custom notifications for different types of events using one of your verified methods."
          buttons={
            <Button type="button" onClick={openNewNotificationEditor} icon={PlusIcon}>
              Add Notification
            </Button>
          }
        >
          {notifications.length > 0 ? (
            <div className="mt-4 grid grid-cols-1 gap-3 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
              {notifications.map((notification) => (
                <NotificationCard
                  key={notification.id}
                  notification={notification}
                  onEdit={() => setActiveEditor({ type: `edit`, id: notification.id })}
                  onDelete={() => onDeleteNotification(notification.id)}
                />
              ))}
            </div>
          ) : (
            <EmptyState
              icon={BellRingIcon}
              title="No notifications"
              description="Get started by creating a custom notification."
              className="mt-4 bg-white"
              button={{
                text: `Create notification`,
                type: `button`,
                onClick: openNewNotificationEditor,
                icon: PlusIcon,
                variant: `primary`,
              }}
            />
          )}
        </CardContainer>
      </VStack>
      <AddNotificationMethodSlideOver
        open={addMethodOpen}
        onOpenChange={setAddMethodOpen}
        onCreatePending={onCreatePendingMethod}
        onConfirm={onConfirmPendingMethod}
        onComplete={(methodId) => setActiveEditor({ type: `new`, methodId })}
      />
      <NotificationEditorSlideOver
        open={editorOpen}
        notification={activeNotification}
        methods={notificationMethods}
        defaultMethodId={activeEditor?.type === `new` ? activeEditor.methodId : undefined}
        onOpenChange={(open) => {
          if (!open) {
            setActiveEditor(null);
          }
        }}
        onSave={saveActiveNotification}
      />
    </>
  );
};

export default NotificationSettingsPage;
