import Result from '../api/Result';
import * as admin from '../api/admin';
import * as users from '../api/users';
import * as signup from '../api/signup';

export interface ApiClient {
  admin: typeof admin;
  users: typeof users;
  signup: typeof signup;
}

export const liveApiClient: ApiClient = {
  admin,
  users,
  signup,
};

export const throwingApiClient: ApiClient = {
  admin: {
    login: () => {
      throw new Error(`ApiClient.admin.login() not implemented.`);
    },
    requestMagicLink: () => {
      throw new Error(`ApiClient.admin.requestMagicLink() not implemented.`);
    },
    loginFromMagicLink: () => {
      throw new Error(`ApiClient.admin.loginFromMagicLink() not implemented.`);
    },
  },
  users: {
    list: () => {
      throw new Error(`ApiClient.users.list() not implemented.`);
    },
    getUser: () => {
      throw new Error(`ApiClient.users.getUser() not implemented.`);
    },
    getActivityOverview: () => {
      throw new Error(`ApiClient.users.getActivityOverview() not implemented.`);
    },
    getActivityDay: () => {
      throw new Error(`ApiClient.users.getActivityDay() not implemented.`);
    },
    deleteActivityItems: () => {
      throw new Error(`ApiClient.users.deleteActivityItems() not implemented.`);
    },
  },
  signup: {
    joinWaitlist: () => {
      throw new Error(`ApiClient.signup.joinWaitlist() not implemented.`);
    },
  },
};

export const noopApiClient: ApiClient = {
  admin: {
    login: async () => {
      return Result.success({ id: ``, token: `` });
    },
    requestMagicLink: async () => {
      return Result.success(true);
    },
    loginFromMagicLink: async () => {
      return Result.success({ id: ``, token: `` });
    },
  },
  users: {
    list: async () => {
      return Result.success([]);
    },
    getUser: async () => {
      return Result.success({
        __typename: `User`,
        id: ``,
        name: ``,
        screenshotsEnabled: false,
        screenshotsResolution: 0,
        screenshotsFrequency: 0,
        keyloggingEnabled: false,
        keychains: [],
        devices: [],
      });
    },
    getActivityOverview: async () => {
      return Result.success({ user: { __typename: `User`, name: `` }, counts: [] });
    },
    getActivityDay: async () => {
      return Result.success({ counts: [], items: [] });
    },
    deleteActivityItems: async () => {
      return Result.success([]);
    },
  },
  signup: {
    joinWaitlist: async () => {
      return Result.success(true);
    },
  },
};
