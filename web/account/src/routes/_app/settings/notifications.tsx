import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { NotificationMethodDraft } from '#/components/settings/notifications/AddNotificationMethodSlideOver';
import type { NotificationDraft } from '#/components/settings/notifications/NotificationEditorSlideOver';
import NotificationSettingsPage from '#/components/pages/settings/NotificationSettingsPage';
import { notificationMethodInput, notificationSettingsViewModel } from '#/lib/settings';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const NotificationSettingsRoute: React.FC = () => {
  const query = useQuery(Key.accountSettings, () => liveClient.getAccountSettings());
  const createMethod = useMutation(liveClient.createAccountNotificationMethod, {
    toast: {
      loading: `Sending verification…`,
      success: `Verification sent`,
      error: `Couldn't send verification`,
    },
  });
  const confirmMethod = useMutation(liveClient.confirmAccountNotificationMethod, {
    invalidating: [Key.accountSettings],
    toast: {
      loading: `Verifying method…`,
      success: `Notification method added`,
      error: `Couldn't verify that code`,
    },
  });
  const saveNotification = useMutation(liveClient.saveAccountNotification, {
    invalidating: [Key.accountSettings],
    toast: {
      loading: `Saving notification…`,
      success: `Notification saved`,
      error: `Couldn't save notification`,
    },
  });
  const deleteNotification = useMutation(liveClient.deleteAccountNotification, {
    invalidating: [Key.accountSettings],
    toast: {
      loading: `Deleting notification…`,
      success: `Notification deleted`,
      error: `Couldn't delete notification`,
    },
  });
  const deleteMethod = useMutation(liveClient.deleteAccountNotificationMethod, {
    invalidating: [Key.accountSettings],
    toast: {
      loading: `Deleting method…`,
      success: `Notification method deleted`,
      error: `Couldn't delete notification method`,
    },
  });
  const setDailyReviewEmail = useMutation(liveClient.setAccountDailyReviewEmail, {
    invalidating: [Key.accountSettings],
    toast: {
      loading: `Updating reminder…`,
      success: `Reminder updated`,
      error: `Couldn't update reminder`,
    },
  });

  if (!query.data) {
    return null;
  }

  const viewModel = notificationSettingsViewModel(query.data);
  const createPendingMethod = async (
    draft: NotificationMethodDraft,
  ): Promise<{ methodId: string; ntfyTopic?: string }> =>
    createMethod.mutateAsync(notificationMethodInput(draft));
  const confirmPendingMethod = async (methodId: string, code: number): Promise<void> => {
    await confirmMethod.mutateAsync({ id: methodId, code });
  };
  const createNewNotification = async (draft: NotificationDraft): Promise<void> => {
    await saveNotification.mutateAsync({
      id: crypto.randomUUID(),
      isNew: true,
      methodId: draft.methodId,
      trigger: draft.trigger,
    });
  };
  const updateNotification = async (
    id: string,
    draft: NotificationDraft,
  ): Promise<void> => {
    await saveNotification.mutateAsync({
      id,
      isNew: false,
      methodId: draft.methodId,
      trigger: draft.trigger,
    });
  };

  return (
    <NotificationSettingsPage
      accountEmail={query.data.email}
      dailyReviewEmail={query.data.dailyReviewEmail}
      hasMacScreenshotUsers={query.data.hasMacScreenshotUsers}
      settingDailyReviewEmail={setDailyReviewEmail.isPending}
      notificationMethods={viewModel.notificationMethods}
      notifications={viewModel.notifications}
      onSetDailyReviewEmail={(enabled) => setDailyReviewEmail.mutate({ enabled })}
      onCreatePendingMethod={createPendingMethod}
      onConfirmPendingMethod={confirmPendingMethod}
      onDeleteMethod={(id) => deleteMethod.mutate({ id })}
      onCreateNotification={createNewNotification}
      onUpdateNotification={updateNotification}
      onDeleteNotification={(id) => deleteNotification.mutate({ id })}
    />
  );
};

export const Route = createFileRoute(`/_app/settings/notifications`)({
  component: NotificationSettingsRoute,
});
