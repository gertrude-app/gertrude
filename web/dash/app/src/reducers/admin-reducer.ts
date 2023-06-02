import { produce } from 'immer';
import { typesafe } from '@shared/ts-utils';
import type { NotificationUpdate } from '@dash/components';
import type {
  GetAdmin,
  NewAdminNotificationMethodEvent,
  PendingNotificationMethod,
} from '@dash/types';
import { editable, Req, revert } from '../lib/helpers';

export type State = {
  notifications: Record<UUID, Editable<GetAdmin.Notification> & { editing?: boolean }>;
  notificationMethods: Record<UUID, GetAdmin.VerifiedNotificationMethod>;
  pendingNotificationMethod?: PendingNotificationMethod;
  deleting: {
    notification?: UUID;
    notificationMethod?: UUID;
  };
};

type Action =
  | { type: 'receivedAdmin'; admin: GetAdmin.Output }
  | { type: 'notificationCreated'; id: UUID }
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
        state.notificationMethods[method.value.id] = method;
      }

      return;

    case `notificationCreated`: {
      const id = action.id;
      state.notifications[id] = {
        editing: true,
        ...editable(
          {
            id,
            trigger: `suspendFilterRequestSubmitted`,
            methodId: typesafe.objectValues(state.notificationMethods)[0]?.value.id ?? ``,
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
            type: `Email`,
            value: { email: `` },
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
          if (state.pendingNotificationMethod?.type === `Email`) {
            state.pendingNotificationMethod.value.email = action.event.email;
          }
          return;
        case `slackChannelNameUpdated`:
          if (state.pendingNotificationMethod?.type === `Slack`) {
            state.pendingNotificationMethod.value.channelName = action.event.channelName;
          }
          return;
        case `slackChannelIdUpdated`:
          if (state.pendingNotificationMethod?.type === `Slack`) {
            state.pendingNotificationMethod.value.channelId = action.event.channelId;
          }
          return;
        case `slackTokenUpdated`:
          if (state.pendingNotificationMethod?.type === `Slack`) {
            state.pendingNotificationMethod.value.token = action.event.token;
          }
          return;
        case `textPhoneNumberUpdated`:
          if (state.pendingNotificationMethod?.type === `Text`) {
            state.pendingNotificationMethod.value.phoneNumber = action.event.phoneNumber;
          }
          return;
        case `methodTypeUpdated`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.type = action.event.methodType;
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
): GetAdmin.VerifiedNotificationMethod {
  switch (pending.type) {
    case `Email`:
      return {
        type: `VerifiedEmailMethod`,
        value: { id: id, email: pending.value.email },
      };
    case `Slack`:
      return {
        type: `VerifiedSlackMethod`,
        value: {
          id: id,
          channelId: pending.value.channelId,
          channelName: pending.value.channelName,
          token: pending.value.token,
        },
      };
    case `Text`:
      return {
        type: `VerifiedTextMethod`,
        value: { id: id, phoneNumber: pending.value.phoneNumber },
      };
  }
}
