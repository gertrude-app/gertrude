import Result from '../api/Result';
import * as users from '../api/users';
import * as signup from '../api/signup';

export interface ApiClient {
  users: typeof users;
  signup: typeof signup;
}

export const liveApiClient: ApiClient = {
  users,
  signup,
};

export const throwingApiClient: ApiClient = {
  users: {
    list: () => {
      throw new Error(`ApiClient.users.list() not implemented.`);
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
  users: {
    list: async () => {
      return Result.success([]);
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
