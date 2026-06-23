import { Button, EmptyState } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import { BellRingIcon, PlusIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import AddNotificationMethodSlideOver from '#/components/settings/AddNotificationMethodSlideOver';
import NotificationCard from '#/components/settings/NotificationCard';
import NotificationEditorSlideOver, {
  type NotificationDraft,
} from '#/components/settings/NotificationEditorSlideOver';
import NotificationMethodChip from '#/components/settings/NotificationMethodChip';
import { getNotificationSettingsPage, useMockData } from '#/lib/mock';

type ActiveNotificationEditor = { type: `new` } | { type: `edit`; id: string } | null;

const NotificationSettingsPage: React.FC = () => {
  const [addMethodOpen, setAddMethodOpen] = React.useState(false);
  const [activeEditor, setActiveEditor] = React.useState<ActiveNotificationEditor>(null);
  const { db, dispatch } = useMockData();
  const { notificationMethods, notifications } = getNotificationSettingsPage(db);
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
      dispatch({
        type: `notification.update`,
        id: activeEditor.id,
        patch: draft,
      });
    } else {
      dispatch({
        type: `notification.create`,
        notification: {
          id: newNotificationId(),
          methodId: draft.methodId,
          trigger: draft.trigger,
          enabled: true,
        },
      });
    }

    setActiveEditor(null);
  };

  const deleteNotification = (id: string): void => {
    dispatch({ type: `notification.delete`, id });
    setActiveEditor((current) =>
      current?.type === `edit` && current.id === id ? null : current,
    );
  };

  const deleteNotificationMethod = (id: string): void => {
    dispatch({ type: `notificationMethod.delete`, id });
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
          buttons={[
            <Button type="button" onClick={() => setAddMethodOpen(true)} icon={PlusIcon}>
              Add Method
            </Button>,
          ]}
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
          buttons={[
            <Button type="button" onClick={openNewNotificationEditor} icon={PlusIcon}>
              Add Notification
            </Button>,
          ]}
        >
          {notifications.length > 0 ? (
            <div className="mt-4 grid grid-cols-1 gap-3 @3xl/main:grid-cols-2 @5xl/main:grid-cols-3">
              {notifications.map((notification) => (
                <NotificationCard
                  key={notification.id}
                  notification={notification}
                  onEdit={() => setActiveEditor({ type: `edit`, id: notification.id })}
                  onDelete={() => deleteNotification(notification.id)}
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

export const Route = createFileRoute(`/_app/settings/notifications`)({
  component: NotificationSettingsPage,
});

function newNotificationId(): string {
  return typeof crypto !== `undefined` && crypto.randomUUID
    ? crypto.randomUUID()
    : `notification-${Date.now()}`;
}
