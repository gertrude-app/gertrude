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
}

export function initialState(): AdminState {
  return {
    profileRequest: Req.idle(),
    verifiedNotificationMethods: {},
    notifications: {},
    listKeychainsRequest: Req.idle(),
  };
}

export const slice = createSlice({
  name: `admin`,
  initialState,
  reducers: {
    startKeychainDelete(state, action: PayloadAction<UUID>) {
      state.pendingDeletionKeychainId = action.payload;
    },
    cancelKeychainDelete(state) {
      delete state.pendingDeletionKeychainId;
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

      for (const method of payload.verifiedNotificationMethods) {
        state.verifiedNotificationMethods[method.id] = {
          id: method.id,
          deletable:
            method.method.data.__typename !== `EmailData` ||
            method.method.data.email !== payload.email,
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

      for (const notification of payload.notifications) {
        state.notifications[notification.id] = {
          id: notification.id,
          trigger: notification.trigger,
          methodId: notification.method.id,
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
  },
});

export const fetchProfileData = createResultThunk(
  `${slice.name}/fetchProfileData`,
  Current.api.admin.getAdmin,
);

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  Current.api.keychains.deleteKeychain,
);

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.admin.listKeychains,
);

export const { startKeychainDelete, cancelKeychainDelete } = slice.actions;

export default slice.reducer;
