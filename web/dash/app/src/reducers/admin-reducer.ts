import { typesafe } from '@shared/ts-utils';
import { produce } from 'immer';
import type { NotificationUpdate } from '@dash/components';
import type {
  AdminNotification,
  GetAdmin,
  NewAdminNotificationMethodEvent,
  PendingNotificationMethod,
  VerifiedNotificationMethod,
} from '@dash/types';
import { Req, editable, revert } from '../lib/helpers';

export type State = {
  notifications: Record<UUID, Editable<AdminNotification> & { editing?: boolean }>;
  notificationMethods: Record<UUID, VerifiedNotificationMethod>;
  pendingNotificationMethod?: PendingNotificationMethod;
  deleting: {
    notification?: UUID;
    notificationMethod?: UUID;
  };
};

type Action =
  | { type: `receivedAdmin`; admin: GetAdmin.Output }
  | { type: `notificationCreated`; id: UUID; methodId?: UUID }
  | { type: `newNotificationMethodEvent`; event: NewAdminNotificationMethodEvent }
  | { type: `updateNotification`; update: NotificationUpdate };

export function reducer(state: State, action: Action): State | undefined {
  switch (action.type) {
    case `receivedAdmin`:
      state.notifications = {};
      for (const notification of action.admin.notifications) {
        state.notifications[notification.id] = {
          editing: false,
          ...editable(notification),
        };
      }

      state.notificationMethods = {};
      for (const method of action.admin.verifiedNotificationMethods) {
        state.notificationMethods[method.id] = method;
      }

      return;

    case `notificationCreated`: {
      const id = action.id;
      const methodId =
        action.methodId ?? typesafe.objectValues(state.notificationMethods)[0]?.id ?? ``;
      state.notifications[id] = {
        editing: true,
        ...editable(
          {
            id,
            trigger: `suspendFilterRequestSubmitted`,
            methodId,
          },
          true,
        ),
      };

      return;
    }

    case `newNotificationMethodEvent`:
      switch (action.event.type) {
        case `createClicked`:
          state.pendingNotificationMethod = {
            sendCodeRequest: Req.idle(),
            confirmationRequest: Req.idle(),
            confirmationCode: ``,
            case: `email`,
            email: ``,
          };
          return;
        case `cancelClicked`:
          delete state.pendingNotificationMethod;
          return;
        case `codeUpdated`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.confirmationCode = action.event.code;
          }
          return;
        case `emailAddressUpdated`:
          if (state.pendingNotificationMethod?.case === `email`) {
            state.pendingNotificationMethod.email = action.event.email;
          }
          return;
        case `slackChannelNameUpdated`:
          if (state.pendingNotificationMethod?.case === `slack`) {
            state.pendingNotificationMethod.channelName = action.event.channelName;
          }
          return;
        case `slackChannelIdUpdated`:
          if (state.pendingNotificationMethod?.case === `slack`) {
            state.pendingNotificationMethod.channelId = action.event.channelId;
          }
          return;
        case `slackTokenUpdated`:
          if (state.pendingNotificationMethod?.case === `slack`) {
            state.pendingNotificationMethod.token = action.event.token;
          }
          return;
        case `textPhoneNumberUpdated`:
          if (state.pendingNotificationMethod?.case === `text`) {
            state.pendingNotificationMethod.phoneNumber = action.event.phoneNumber;
          }
          return;
        case `methodTypeUpdated`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.case = action.event.methodType;
          }
          return;
        case `createPendingMethodStarted`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.sendCodeRequest = Req.ongoing();
          }
          return;
        case `createPendingMethodSucceeded`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.sendCodeRequest = Req.succeed(
              action.event.methodId,
            );
          }
          return;
        case `createPendingMethodFailed`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.sendCodeRequest = Req.fail();
          }
          return;
        case `confirmPendingMethodStarted`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.confirmationRequest = Req.ongoing();
          }
          return;
        case `confirmPendingMethodSucceeded`:
          if (state.pendingNotificationMethod) {
            const newId =
              Req.payload(state.pendingNotificationMethod.sendCodeRequest) ?? ``;
            state.notificationMethods[newId] = toVerifiedMethod(
              state.pendingNotificationMethod,
              newId,
            );
            delete state.pendingNotificationMethod;
          }
          return;
        case `confirmPendingMethodFailed`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.confirmationRequest = Req.fail();
          }
          return;
      }
      return;

    case `updateNotification`: {
      const notification = state.notifications[action.update.id];
      if (!notification) return;

      switch (action.update.type) {
        case `startEditing`:
          notification.editing = true;
          return;

        case `cancelEditing`:
          state.notifications[action.update.id] = {
            editing: false,
            ...revert(notification),
          };
          return;

        case `changeTrigger`:
          notification.draft.trigger = action.update.trigger;
          return;

        case `changeMethod`:
          notification.draft.methodId = action.update.methodId;
          return;
      }
    }
  }
}

export const initialState: State = {
  notificationMethods: {},
  notifications: {},
  deleting: {},
};

export default produce(reducer);

function toVerifiedMethod(
  pending: PendingNotificationMethod,
  id: UUID,
): VerifiedNotificationMethod {
  switch (pending.case) {
    case `email`:
      return { id, config: { case: `email`, email: pending.email } };
    case `text`:
      return { id, config: { case: `text`, phoneNumber: pending.phoneNumber } };
    case `slack`:
      return {
        id,
        config: {
          case: `slack`,
          channelId: pending.channelId,
          channelName: pending.channelName,
          token: pending.token,
        },
      };
  }
}
