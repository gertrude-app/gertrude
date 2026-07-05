import { Button, EmptyState } from '@gertrude/ui';
import { BellRingIcon, PlusIcon } from 'lucide-react';
import React from 'react';
import type { Notification, NotificationMethod } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import AddNotificationMethodSlideOver, {
  type NotificationMethodDraft,
} from '#/components/settings/notifications/AddNotificationMethodSlideOver';
import NotificationCard from '#/components/settings/notifications/NotificationCard';
import NotificationEditorSlideOver, {
  type NotificationDraft,
} from '#/components/settings/notifications/NotificationEditorSlideOver';
import NotificationMethodChip from '#/components/settings/notifications/NotificationMethodChip';

type ActiveNotificationEditor = { type: `new` } | { type: `edit`; id: string } | null;

interface Props {
  notificationMethods: NotificationMethod[];
  notifications: Notification[];
  onCreateMethod: (draft: NotificationMethodDraft) => void | Promise<void>;
  onDeleteMethod: (id: string) => void;
  onCreateNotification: (draft: NotificationDraft) => void;
  onUpdateNotification: (id: string, draft: NotificationDraft) => void;
  onDeleteNotification: (id: string) => void;
}

const NotificationSettingsPage: React.FC<Props> = ({
  notificationMethods,
  notifications,
  onCreateMethod,
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

  const saveActiveNotification = (draft: NotificationDraft): void => {
    if (!activeEditor) {
      return;
    }

    if (activeEditor.type === `edit`) {
      onUpdateNotification(activeEditor.id, draft);
    } else {
      onCreateNotification(draft);
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
      <div className="mt-4 flex flex-col gap-4">
        <CardContainer
          heading="Methods"
          subheading="Verified ways that Gertrude can notify you for child requests and events."
          buttons={
            <Button type="button" onClick={() => setAddMethodOpen(true)} icon={PlusIcon}>
              Add Method
            </Button>
          }
        >
          <div className="mt-4 flex flex-wrap gap-2">
            {notificationMethods.map((method) => (
              <NotificationMethodChip
                key={method.id}
                method={method}
                notificationCount={
                  notifications.filter(
                    (notification) => notification.methodId === method.id,
                  ).length
                }
                onDelete={() => deleteNotificationMethod(method.id)}
              />
            ))}
          </div>
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
      </div>
      <AddNotificationMethodSlideOver
        open={addMethodOpen}
        onOpenChange={setAddMethodOpen}
        onComplete={onCreateMethod}
      />
      <NotificationEditorSlideOver
        open={editorOpen}
        notification={activeNotification}
        methods={notificationMethods}
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
