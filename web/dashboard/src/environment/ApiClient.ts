import Result from '../api/Result';
import * as users from '../api/users';
import * as signup from '../api/signup';

export interface ApiClient {
  users: {
    list(): ReturnType<typeof users.list>;
  };
  signup: {
    joinWaitlist(email: string): ReturnType<typeof signup.joinWaitlist>;
  };
}

export const liveApiClient: ApiClient = {
  users: {
    list(): ReturnType<typeof users.list> {
      return users.list();
    },
  },
  signup: {
    joinWaitlist(email: string): ReturnType<typeof signup.joinWaitlist> {
      return signup.joinWaitlist(email);
    },
  },
};

export const throwingApiClient: ApiClient = {
  users: {
    list(): ReturnType<typeof users.list> {
      throw new Error(`ApiClient.users.list() not implemented.`);
    },
  },
  signup: {
    joinWaitlist(_email: string): ReturnType<typeof signup.joinWaitlist> {
      throw new Error(`ApiClient.signup.joinWaitlist() not implemented.`);
    },
  },
};

export const noopApiClient: ApiClient = {
  users: {
    list(): ReturnType<typeof users.list> {
      return Promise.resolve(Result.success([]));
    },
  },
  signup: {
    joinWaitlist(_email: string): ReturnType<typeof signup.joinWaitlist> {
      return Promise.resolve(Result.success(true));
    },
  },
};
