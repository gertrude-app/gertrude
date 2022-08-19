import Result from '../api/Result';
import * as users from '../api/users';
import * as signup from '../api/signup';
import { DateRangeInput } from '../graphqlTypes';

export interface ApiClient {
  users: {
    list(): ReturnType<typeof users.list>;
    getActivityOverview(
      userId: string,
      ranges?: DateRangeInput[],
    ): ReturnType<typeof users.getActivityOverview>;
    getActivityDay(userId: string, day: Date): ReturnType<typeof users.getActivityDay>;
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
    getActivityOverview(
      userId: string,
      ranges?: DateRangeInput[],
    ): ReturnType<typeof users.getActivityOverview> {
      return users.getActivityOverview(userId, ranges);
    },
    getActivityDay(userId: string, day: Date): ReturnType<typeof users.getActivityDay> {
      return users.getActivityDay(userId, day);
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
    getActivityOverview(
      _userId: string,
      _ranges?: DateRangeInput[],
    ): ReturnType<typeof users.getActivityOverview> {
      throw new Error(`ApiClient.users.getActivityOverview() not implemented.`);
    },
    getActivityDay(_userId: string, _day: Date): ReturnType<typeof users.getActivityDay> {
      throw new Error(`ApiClient.users.getActivityDay() not implemented.`);
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
    getActivityOverview(
      _userId: string,
      _ranges?: DateRangeInput[],
    ): ReturnType<typeof users.getActivityOverview> {
      return Promise.resolve(
        Result.success({ user: { __typename: `User`, name: `` }, counts: [] }),
      );
    },
    getActivityDay(_userId: string, _day: Date): ReturnType<typeof users.getActivityDay> {
      return Promise.resolve(Result.success([]));
    },
  },
  signup: {
    joinWaitlist(_email: string): ReturnType<typeof signup.joinWaitlist> {
      return Promise.resolve(Result.success(true));
    },
  },
};
