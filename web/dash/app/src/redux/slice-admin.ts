import { createSlice } from '@reduxjs/toolkit';
import { isUnsaved, unsavedId } from '@dash/utils';
import { typesafe } from '@shared/ts-utils';
import { Result } from '@dash/types';
import type {
  GetAdmin,
  PendingNotificationMethod,
  NewAdminNotificationMethodEvent,
  AdminSubscriptionStatus,
  CreatePendingNotificationMethod,
  RequestState,
} from '@dash/types';
import type { NotificationUpdate } from '@dash/components';
import type { PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { Req, editable, revert, commit } from './helpers';
import { createResultThunk } from './thunk';

export interface AdminState {
  billingPortalRequest: RequestState<string>;
  profileRequest: RequestState<{
    email: string;
    subscriptionStatus: AdminSubscriptionStatus;
  }>;
  notificationMethods: Record<UUID, GetAdmin.VerifiedNotificationMethod>;
  notifications: Record<UUID, Editable<GetAdmin.Notification> & { editing: boolean }>;
  saveNotificationRequests: Record<UUID, RequestState>;
  pendingNotificationMethod?: PendingNotificationMethod;
  deleting: {
    notification?: UUID;
    notificationMethod?: UUID;
  };
}

export function initialState(): AdminState {
  return {
    billingPortalRequest: Req.idle(),
    profileRequest: Req.idle(),
    notificationMethods: {},
    notifications: {},
    saveNotificationRequests: {},
    deleting: {},
  };
}

type DeletableEntity = 'notification' | 'notificationMethod';

export const slice = createSlice({
  name: `admin`,
  initialState,
  reducers: {
    startAdminEntityDelete(
      state,
      action: PayloadAction<{ type: DeletableEntity; id: UUID }>,
    ) {
      state.deleting[action.payload.type] = action.payload.id;
    },
    cancelAdminEntityDelete(state, { payload: type }: PayloadAction<DeletableEntity>) {
      delete state.deleting[type];
    },
    notificationCreated(state) {
      state.notifications[unsavedId()] = {
        editing: true,
        ...editable({
          id: unsavedId(),
          trigger: `suspendFilterRequestSubmitted`,
          methodId: typesafe.objectValues(state.notificationMethods)[0]?.value.id ?? ``,
        }),
      };
    },
    notificationChanged(state, { payload }: PayloadAction<NotificationUpdate>) {
      const notification = state.notifications[payload.id];
      if (!notification) {
        return;
      }

      switch (payload.type) {
        case `startEditing`:
          notification.editing = true;
          break;
        case `cancelEditing`:
          state.notifications[payload.id] = { editing: false, ...revert(notification) };
          break;
        case `changeTrigger`:
          notification.draft.trigger = payload.trigger;
          break;
        case `changeMethod`:
          notification.draft.methodId = payload.methodId;
          break;
      }
    },
    newNotificationMethodEvent(
      state,
      { payload }: PayloadAction<NewAdminNotificationMethodEvent>,
    ) {
      switch (payload.type) {
        case `create_clicked`:
          state.pendingNotificationMethod = {
            sendCodeRequest: Req.idle(),
            confirmationRequest: Req.idle(),
            confirmationCode: ``,
            type: `Email`,
            value: { email: `` },
          };
          break;
        case `cancel_clicked`:
          delete state.pendingNotificationMethod;
          break;
        case `code_updated`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.confirmationCode = payload.code;
          }
          break;
        case `email_address_updated`:
          if (state.pendingNotificationMethod?.type === `Email`) {
            state.pendingNotificationMethod.value.email = payload.email;
          }
          break;
        case `slack_channel_name_updated`:
          if (state.pendingNotificationMethod?.type === `Slack`) {
            state.pendingNotificationMethod.value.channelName = payload.channelName;
          }
          break;
        case `slack_channel_id_updated`:
          if (state.pendingNotificationMethod?.type === `Slack`) {
            state.pendingNotificationMethod.value.channelId = payload.channelId;
          }
          break;
        case `slack_token_updated`:
          if (state.pendingNotificationMethod?.type === `Slack`) {
            state.pendingNotificationMethod.value.token = payload.token;
          }
          break;
        case `text_phone_number_updated`:
          if (state.pendingNotificationMethod?.type === `Text`) {
            state.pendingNotificationMethod.value.phoneNumber = payload.phoneNumber;
          }
          break;
        case `method_type_updated`:
          if (state.pendingNotificationMethod) {
            state.pendingNotificationMethod.type = payload.methodType;
          }
          break;
      }
    },
  },
  extraReducers: (builder) => {
    builder.addCase(fetchProfileData.started, (state) => {
      state.profileRequest = Req.ongoing();
    });

    builder.addCase(fetchProfileData.succeeded, (state, { payload }) => {
      state.profileRequest = Req.succeed({
        email: payload.email,
        subscriptionStatus: payload.subscriptionStatus,
      });

      for (const notification of payload.notifications) {
        state.notifications[notification.id] = {
          editing: false,
          ...editable(notification),
        };
      }

      for (const method of payload.verifiedNotificationMethods) {
        state.notificationMethods[method.value.id] = method;
      }
    });

    builder.addCase(fetchProfileData.failed, (state, { error }) => {
      state.profileRequest = Req.fail(error);
    });

    builder.addCase(deleteNotification.started, (state) => {
      delete state.deleting.notification;
    });

    builder.addCase(deleteNotification.succeeded, (state, { meta }) => {
      delete state.notifications[meta.arg];
    });

    builder.addCase(createBillingPortalSession.started, (state) => {
      state.billingPortalRequest = Req.ongoing();
    });

    builder.addCase(createBillingPortalSession.failed, (state, { error }) => {
      state.billingPortalRequest = Req.fail(error);
    });

    builder.addCase(createBillingPortalSession.succeeded, (state, { payload }) => {
      state.billingPortalRequest = Req.succeed(payload.url);
    });

    builder.addCase(deleteNotificationMethod.started, (state) => {
      delete state.deleting.notificationMethod;
    });

    builder.addCase(deleteNotificationMethod.succeeded, (state, { meta }) => {
      delete state.notificationMethods[meta.arg];
    });

    builder.addCase(upsertNotification.started, (state, { meta: { arg } }) => {
      state.saveNotificationRequests[arg] = Req.ongoing();
    });

    builder.addCase(upsertNotification.failed, (state, { error, meta: { arg } }) => {
      state.saveNotificationRequests[arg] = Req.fail(error);
    });

    builder.addCase(upsertNotification.succeeded, (state, { payload, meta: { arg } }) => {
      state.saveNotificationRequests[arg] = Req.succeed(void 0);
      const notification = state.notifications[payload.id] ?? state.notifications[arg];
      if (notification) {
        notification.original.id = payload.id;
        notification.draft.id = payload.id;
        state.notifications[payload.id] = { editing: false, ...commit(notification) };
        if (isUnsaved(arg)) {
          delete state.notifications[arg];
        }
      }
    });

    builder.addCase(createPendingNotificationMethod.started, (state) => {
      if (state.pendingNotificationMethod) {
        state.pendingNotificationMethod.sendCodeRequest = Req.ongoing();
      }
    });

    builder.addCase(createPendingNotificationMethod.failed, (state, { error }) => {
      if (state.pendingNotificationMethod) {
        state.pendingNotificationMethod.sendCodeRequest = Req.fail(error);
      }
    });

    builder.addCase(createPendingNotificationMethod.succeeded, (state, { payload }) => {
      if (state.pendingNotificationMethod) {
        state.pendingNotificationMethod.sendCodeRequest = Req.succeed(payload.methodId);
      }
    });

    builder.addCase(confirmPendingNotificationMethod.started, (state) => {
      if (state.pendingNotificationMethod) {
        state.pendingNotificationMethod.confirmationRequest = Req.ongoing();
      }
    });

    builder.addCase(confirmPendingNotificationMethod.failed, (state, { error }) => {
      if (state.pendingNotificationMethod) {
        state.pendingNotificationMethod.confirmationRequest = Req.fail(error);
      }
    });

    builder.addCase(confirmPendingNotificationMethod.succeeded, (state) => {
      if (state.pendingNotificationMethod) {
        const newId = Req.payload(state.pendingNotificationMethod.sendCodeRequest) ?? ``;
        state.notificationMethods[newId] = toVerifiedMethod(
          state.pendingNotificationMethod,
          newId,
        );
        delete state.pendingNotificationMethod;
      }
    });
  },
});

export const fetchProfileData = createResultThunk(
  `${slice.name}/fetchProfileData`,
  Current.api.getAdmin,
);

export const deleteNotificationMethod = createResultThunk(
  `${slice.name}/deleteNotificationMethod`,
  (id: UUID) => Current.api.deleteEntity({ id, type: `AdminVerifiedNotificationMethod` }),
);

export const deleteNotification = createResultThunk(
  `${slice.name}/deleteNotification`,
  (id: UUID) => Current.api.deleteEntity({ id, type: `AdminNotification` }),
);

export const createBillingPortalSession = createResultThunk(
  `${slice.name}/createBillingPortalSession`,
  Current.api.createBillingPortalSession,
);

export const upsertNotification = createResultThunk(
  `${slice.name}/upsertNotification`,
  async (id: UUID, { getState }) => {
    const state = getState();
    const notification = state.admin.notifications[id];
    if (!notification) {
      return Result.unexpectedError(`1662407a`, `Notification ${id} not found`);
    }
    return Current.api.saveNotification({
      id: isUnsaved(notification.draft.id) ? undefined : notification.draft.id,
      methodId: notification.draft.methodId,
      trigger: notification.draft.trigger,
    });
  },
);

export const createPendingNotificationMethod = createResultThunk(
  `${slice.name}/createPendingNotificationMethod`,
  async (_: void, { getState }) => {
    const pendingMethod = getState().admin.pendingNotificationMethod;
    if (!pendingMethod) {
      return Result.unexpectedError(`ae1d1cab`, `missing pendingMethod`);
    }
    return Current.api.createPendingNotificationMethod(toInput(pendingMethod));
  },
);

export const confirmPendingNotificationMethod = createResultThunk(
  `${slice.name}/confirmPendingNotificationMethod`,
  (_: void, { getState }) => {
    const pendingMethod = getState().admin.pendingNotificationMethod;
    return Current.api.confirmPendingNotificationMethod({
      id: Req.payload(pendingMethod?.sendCodeRequest) ?? ``,
      code: Number(pendingMethod?.confirmationCode),
    });
  },
);

export const {
  startAdminEntityDelete,
  cancelAdminEntityDelete,
  notificationChanged,
  notificationCreated,
  newNotificationMethodEvent,
} = slice.actions;

export default slice.reducer;

// helpers

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

function toInput(
  pending: PendingNotificationMethod,
): CreatePendingNotificationMethod.Input {
  switch (pending.type) {
    case `Email`:
      return { type: `Email`, value: pending.value };
    case `Text`:
      return { type: `Text`, value: pending.value };
    case `Slack`:
      return { type: `Slack`, value: pending.value };
  }
}
