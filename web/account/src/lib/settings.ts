import { parseE164 } from '@shared/phone-numbers';
import type { NotificationMethodDraft } from '#/components/settings/notifications/AddNotificationMethodSlideOver';
import type { Notification, NotificationMethod } from '#/components/types';
import type {
  GetAccountSettings,
  NotificationMethodConfig,
} from '@shared/pairql/src/account';

export function notificationSettingsViewModel(settings: GetAccountSettings.Output): {
  notificationMethods: NotificationMethod[];
  notifications: Notification[];
} {
  const notificationMethods = settings.notificationMethods.map(
    notificationMethodViewModel,
  );
  const methodsById = new Map(notificationMethods.map((method) => [method.id, method]));
  const notifications = settings.notifications.flatMap((notification) => {
    const method = methodsById.get(notification.methodId);
    return method
      ? [
          {
            id: notification.id,
            methodId: notification.methodId,
            trigger: notification.trigger,
            method,
          },
        ]
      : [];
  });

  return { notificationMethods, notifications };
}

export function notificationMethodInput(
  draft: NotificationMethodDraft,
): NotificationMethodConfig {
  switch (draft.type) {
    case `email`:
      return { case: `email`, email: draft.emailAddress };
    case `text`: {
      const phoneNumber = parseE164(draft.phoneNumber);
      if (!phoneNumber) {
        throw new Error(`Invalid notification phone number`);
      }
      return { case: `text`, phoneNumber };
    }
    case `slack`:
      return {
        case: `slack`,
        channelName: draft.channelName,
        channelId: draft.channelId,
        token: draft.botToken,
      };
    case `ntfy`:
      return { case: `ntfy`, topic: `` };
  }
}

function notificationMethodViewModel(
  method: GetAccountSettings.Output[`notificationMethods`][number],
): NotificationMethod {
  switch (method.config.case) {
    case `email`:
      return { id: method.id, type: `email`, emailAddress: method.config.email };
    case `text`:
      return { id: method.id, type: `text`, phoneNumber: method.config.phoneNumber };
    case `slack`:
      return {
        id: method.id,
        type: `slack`,
        channelName: method.config.channelName,
        channelId: method.config.channelId,
        botToken: method.config.token,
      };
    case `ntfy`:
      return { id: method.id, type: `ntfy`, topicId: method.config.topic };
  }
}
