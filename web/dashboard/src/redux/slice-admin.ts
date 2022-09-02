import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ListAdminKeychains } from '../api/admin/__generated__/ListAdminKeychains';
import Current from '../environment';
import { Admin, Notification, VerifiedNotificationMethod } from '../types/Admin';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface AdminState {
  profileRequest: RequestState<Admin>;
  verifiedNotificationMethods: Record<UUID, VerifiedNotificationMethod>;
  notifications: Record<UUID, Notification>;
  listKeychainsRequest: RequestState<ListAdminKeychains['keychains']>;
  pendingDeletionKeychainId?: UUID;
  pendingDeletionNotificationId?: UUID;
  pendingDeletionVerifiedNotificationMethodId?: UUID;
}

export function initialState(): AdminState {
  return {
    profileRequest: Req.idle(),
    verifiedNotificationMethods: {},
    notifications: {},
    listKeychainsRequest: Req.idle(),
  };
}

type DeletableEntity = 'Keychain' | 'Notification' | 'VerifiedNotificationMethod';

export const slice = createSlice({
  name: `admin`,
  initialState,
  reducers: {
    startEntityDelete(state, action: PayloadAction<{ type: DeletableEntity; id: UUID }>) {
      state[`pendingDeletion${action.payload.type}Id`] = action.payload.id;
    },
    cancelEntityDelete(state, { payload: type }: PayloadAction<DeletableEntity>) {
      delete state[`pendingDeletion${type}Id`];
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
          id: notification.id,
          trigger: notification.trigger,
          methodId: notification.method.id,
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
      delete state.pendingDeletionKeychainId;
    });

    builder.addCase(deleteKeychain.succeeded, (state, { meta }) => {
      if (state.listKeychainsRequest.state === `succeeded`) {
        state.listKeychainsRequest.payload = state.listKeychainsRequest.payload.filter(
          (keychain) => keychain.id !== meta.arg,
        );
      }
    });

    builder.addCase(deleteNotification.started, (state) => {
      delete state.pendingDeletionNotificationId;
    });

    builder.addCase(deleteNotification.succeeded, (state, { meta }) => {
      delete state.notifications[meta.arg];
    });

    builder.addCase(deleteNotificationMethod.started, (state) => {
      delete state.pendingDeletionVerifiedNotificationMethodId;
    });

    builder.addCase(deleteNotificationMethod.succeeded, (state, { meta }) => {
      delete state.verifiedNotificationMethods[meta.arg];
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

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  Current.api.keychains.deleteKeychain,
);

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.admin.listKeychains,
);

export const { startEntityDelete, cancelEntityDelete } = slice.actions;

export default slice.reducer;
