import { expect, it, describe } from 'vitest';
import { Req } from '../helpers';
import reducer, { fetchProfileData } from '../slice-admin';
import { makeState } from './test-helpers';
import * as mock from './mocks';
import { SubscriptionStatus, Trigger } from '../../graphqlTypes';

describe(`fetchProfileData`, () => {
  it(`.succeeded sets correctly massaged data on state slice`, () => {
    const apiData = mock.adminProfile({
      email: `blob@blob.com`,
      subscriptionStatus: SubscriptionStatus.trialing,
      verifiedNotificationMethods: [
        mock.adminVerifiedNotificationMethod({
          id: `verifiedMethod1`,
          method: mock.notificationMethod({
            data: { __typename: `EmailData`, email: `blob@blob.com` },
          }),
        }),
        mock.adminVerifiedNotificationMethod({
          id: `verifiedMethod2`,
          method: mock.notificationMethod({
            data: { __typename: `TextData`, phoneNumber: `7` },
          }),
        }),
      ],
      notifications: [
        mock.adminNotification({
          id: `notification1`,
          trigger: Trigger.unlockRequestSubmitted,
          method: {
            __typename: `AdminVerifiedNotificationMethod`,
            id: `verifiedMethod2`,
          },
        }),
      ],
    });

    const nextState = reducer(
      makeState().admin,
      fetchProfileData.succeeded(apiData, `admin123`),
    );

    expect(nextState.profileRequest).toEqual(
      Req.succeed({
        email: `blob@blob.com`,
        subscriptionStatus: SubscriptionStatus.trialing,
      }),
    );

    expect(nextState.verifiedNotificationMethods).toEqual({
      verifiedMethod1: {
        id: `verifiedMethod1`,
        data: { type: `email`, email: `blob@blob.com` },
      },
      verifiedMethod2: {
        id: `verifiedMethod2`,
        data: { type: `text`, phoneNumber: `7` },
      },
    });

    expect(nextState.notifications).toEqual({
      notification1: {
        id: `notification1`,
        trigger: Trigger.unlockRequestSubmitted,
        methodId: `verifiedMethod2`,
      },
    });
  });
});
