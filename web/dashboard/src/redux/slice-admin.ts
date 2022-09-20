import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { isUnsaved, unsavedId } from '@dashboard/lib/id';
import { NotificationUpdate } from '@dashboard/Profile';
import * as T from '@dashboard/types/Admin';
import { Trigger } from '@dashboard/types/GraphQL';
import Current from '../environment';
import { Req, editable, revert, commit } from './helpers';
import * as typesafe from '../lib/typesafe';
import { createResultThunk } from './thunk';
import Result from '../api/Result';

export interface AdminState {
  profileRequest: RequestState<T.Admin>;
  notificationMethods: Record<UUID, T.AdminNotificationMethod>;
  notifications: Record<UUID, Editable<T.Notification> & { editing: boolean }>;
  saveNotificationRequests: Record<UUID, RequestState>;
  pendingNotificationMethod?: T.PendingNotificationMethod;
  deleting: {
    notification?: UUID;
    notificationMethod?: UUID;
  };
}

export function initialState(): AdminState {
  return {
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
          trigger: Trigger.suspendFilterRequestSubmitted,
          methodId: typesafe.objectValues(state.notificationMethods)[0]?.id ?? ``,
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
      { payload }: PayloadAction<T.NewAdminNotificationMethodEvent>,
    ) {
      switch (payload.type) {
        case `create_clicked`:
          state.pendingNotificationMethod = {
            sendCodeRequest: Req.idle(),
            confirmationRequest: Req.idle(),
            confirmationCode: ``,
            type: `email`,
            email: ``,
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
          if (state.pendingNotificationMethod?.type === `email`) {
            state.pendingNotificationMethod.email = payload.email;
          }
          break;
        case `slack_channel_name_updated`:
          if (state.pendingNotificationMethod?.type === `slack`) {
            state.pendingNotificationMethod.channelName = payload.channelName;
          }
          break;
        case `slack_channel_id_updated`:
          if (state.pendingNotificationMethod?.type === `slack`) {
            state.pendingNotificationMethod.channelId = payload.channelId;
          }
          break;
        case `slack_token_updated`:
          if (state.pendingNotificationMethod?.type === `slack`) {
            state.pendingNotificationMethod.token = payload.token;
          }
          break;
        case `text_phone_number_updated`:
          if (state.pendingNotificationMethod?.type === `text`) {
            state.pendingNotificationMethod.phoneNumber = payload.phoneNumber;
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
          ...editable({
            id: notification.id,
            trigger: notification.trigger,
            methodId: notification.method.id,
          }),
        };
      }

      for (const method of payload.verifiedNotificationMethods) {
        state.notificationMethods[method.id] = {
          id: method.id,
          data: (() => {
            switch (method.method.data.__typename) {
              case `EmailData`:
                return { type: `email`, email: method.method.data.email };
              case `TextData`:
                return { type: `text`, phoneNumber: method.method.data.phoneNumber };
              case `SlackData`:
                return {
                  type: `slack`,
                  token: method.method.data.token,
                  channelId: method.method.data.channelId,
                  channelName: method.method.data.channelName,
                };
            }
          })(),
        };
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
      const notification = state.notifications[payload] ?? state.notifications[arg];
      if (notification) {
        notification.original.id = payload;
        notification.draft.id = payload;
        state.notifications[payload] = { editing: false, ...commit(notification) };
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

    builder.addCase(createPendingNotificationMethod.succeeded, (state, action) => {
      if (state.pendingNotificationMethod) {
        state.pendingNotificationMethod.sendCodeRequest = Req.succeed(action.payload);
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
        state.notificationMethods[newId] = {
          id: newId,
          data: state.pendingNotificationMethod,
        };
        delete state.pendingNotificationMethod;
      }
    });
  },
});

export const fetchProfileData = createResultThunk(
  `${slice.name}/fetchProfileData`,
  Current.api.admin.getAdmin,
);

export const deleteNotificationMethod = createResultThunk(
  `${slice.name}/deleteNotificationMethod`,
  Current.api.admin.deleteNotificationMethod,
);

export const deleteNotification = createResultThunk(
  `${slice.name}/deleteNotification`,
  Current.api.admin.deleteNotification,
);

export const upsertNotification = createResultThunk(
  `${slice.name}/upsertNotification`,
  async (id: UUID, { getState }) => {
    const state = getState();
    const notification = state.admin.notifications[id];
    if (!notification) {
      return Result.error<ApiError>({ type: `non_actionable` });
    }
    return Current.api.admin.upsertNotification({
      adminId: state.auth.admin?.id ?? ``,
      ...notification.draft,
    });
  },
);

export const createPendingNotificationMethod = createResultThunk(
  `${slice.name}/createPendingNotificationMethod`,
  async (_: void, { getState }) => {
    const pendingMethod = getState().admin.pendingNotificationMethod;
    if (!pendingMethod) {
      return Result.error<ApiError>({ type: `non_actionable` });
    }
    return Current.api.admin.createPendingNotificationMethod(pendingMethod);
  },
);

export const confirmPendingNotificationMethod = createResultThunk(
  `${slice.name}/confirmPendingNotificationMethod`,
  (_: void, { getState }) => {
    const pendingMethod = getState().admin.pendingNotificationMethod;
    return Current.api.admin.confirmPendingNotificationMethod(
      Req.payload(pendingMethod?.sendCodeRequest) ?? ``,
      Number(pendingMethod?.confirmationCode),
    );
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
