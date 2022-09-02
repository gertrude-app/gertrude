import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { NotificationUpdate } from '@dashboard/Profile';
import { Admin, Notification, AdminNotificationMethod } from '@dashboard/types/Admin';
import { ListAdminKeychains } from '../api/admin/__generated__/ListAdminKeychains';
import Current from '../environment';
import { Req, editable, revert, commit } from './helpers';
import { createResultThunk } from './thunk';
import Result from '../api/Result';

export interface AdminState {
  profileRequest: RequestState<Admin>;
  verifiedNotificationMethods: Record<UUID, AdminNotificationMethod>;
  notifications: Record<UUID, Editable<Notification> & { editing: boolean }>;
  saveNotificationRequests: Record<UUID, RequestState>;
  listKeychainsRequest: RequestState<ListAdminKeychains['keychains']>;
  deleting: {
    keychain?: UUID;
    notification?: UUID;
    notificationMethod?: UUID;
  };
}

export function initialState(): AdminState {
  return {
    profileRequest: Req.idle(),
    verifiedNotificationMethods: {},
    notifications: {},
    saveNotificationRequests: {},
    listKeychainsRequest: Req.idle(),
    deleting: {},
  };
}

type DeletableEntity = 'keychain' | 'notification' | 'notificationMethod';

export const slice = createSlice({
  name: `admin`,
  initialState,
  reducers: {
    startEntityDelete(state, action: PayloadAction<{ type: DeletableEntity; id: UUID }>) {
      state.deleting[action.payload.type] = action.payload.id;
    },
    cancelEntityDelete(state, { payload: type }: PayloadAction<DeletableEntity>) {
      delete state.deleting[type];
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
  },
  extraReducers: (builder) => {
    builder.addCase(fetchAdminKeychains.started, (state) => {
      state.listKeychainsRequest = Req.ongoing();
    });

    builder.addCase(fetchAdminKeychains.succeeded, (state, { payload }) => {
      state.listKeychainsRequest = Req.succeed(payload);
    });

    builder.addCase(fetchAdminKeychains.failed, (state, { error }) => {
      state.listKeychainsRequest = Req.fail(error);
    });

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
        state.verifiedNotificationMethods[method.id] = {
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

    builder.addCase(deleteKeychain.started, (state) => {
      delete state.deleting.keychain;
    });

    builder.addCase(deleteKeychain.succeeded, (state, { meta }) => {
      if (state.listKeychainsRequest.state === `succeeded`) {
        state.listKeychainsRequest.payload = state.listKeychainsRequest.payload.filter(
          (keychain) => keychain.id !== meta.arg,
        );
      }
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
      delete state.verifiedNotificationMethods[meta.arg];
    });

    builder.addCase(updateNotification.started, (state, { meta: { arg } }) => {
      state.saveNotificationRequests[arg] = Req.ongoing();
    });

    builder.addCase(updateNotification.failed, (state, { error, meta: { arg } }) => {
      state.saveNotificationRequests[arg] = Req.fail(error);
    });

    builder.addCase(updateNotification.succeeded, (state, { meta: { arg } }) => {
      state.saveNotificationRequests[arg] = Req.succeed(void 0);
      const notification = state.notifications[arg];
      if (notification) {
        state.notifications[arg] = { editing: false, ...commit(notification) };
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

export const updateNotification = createResultThunk(
  `${slice.name}/updateNotification`,
  async (id: UUID, { getState }) => {
    const state = getState();
    const notification = state.admin.notifications[id];
    if (!notification) {
      return Result.error<ApiError>({ type: `non_actionable` });
    }
    return Current.api.admin.updateNotification({
      adminId: state.auth.admin?.id ?? ``,
      ...notification.draft,
    });
  },
);

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  Current.api.keychains.deleteKeychain,
);

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.admin.listKeychains,
);

export const { startEntityDelete, cancelEntityDelete, notificationChanged } =
  slice.actions;

export default slice.reducer;
