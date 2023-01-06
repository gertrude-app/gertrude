import { expect, it, test, describe } from 'vitest';
import { unsavedId } from '@dash/utils';
// import { AdminSubscriptionStatus, AdminNotTrigger } from '@dash/types';
import { Req } from '../helpers';
import reducer, {
  confirmPendingNotificationMethod,
  createPendingNotificationMethod,
  fetchProfileData,
  newNotificationMethodEvent,
  notificationCreated,
  upsertNotification,
} from '../slice-admin';
import { makeState } from './test-helpers';
import * as mock from './mocks';

describe(`createNotification flow`, () => {
  test(`happy path, replacing temporary client id`, () => {
    const tempId = unsavedId();
    let state = reducer(undefined, notificationCreated());
    expect(state.notifications[tempId]).toBeDefined();

    state = reducer(state, upsertNotification.succeeded({ id: `apiId` }, tempId));
    expect(state.notifications[tempId]).toBeUndefined();
    expect(state.notifications.apiId).toBeDefined();
  });
});

describe(`create new notification method flow`, () => {
  test(`happy path`, () => {
    // step 1: create a new pending notification method
    let state = reducer(
      undefined,
      newNotificationMethodEvent({ type: `create_clicked` }),
    );
    expect(state.pendingNotificationMethod).toEqual({
      sendCodeRequest: Req.idle(),
      confirmationRequest: Req.idle(),
      confirmationCode: ``,
      type: `Email`,
      value: {
        email: ``,
      },
    });

    // step 2: update the email address to a valid state
    state = reducer(
      state,
      newNotificationMethodEvent({ type: `email_address_updated`, email: `foo@bar.com` }),
    );
    expect(state.pendingNotificationMethod).toMatchObject({
      value: { email: `foo@bar.com` },
    });

    // step 3: simulate a successfull request to generate a code
    state = reducer(
      state,
      createPendingNotificationMethod.succeeded({ methodId: `pendingId` }),
    );
    expect(state.pendingNotificationMethod).toMatchObject({
      sendCodeRequest: Req.succeed(`pendingId`),
    });

    // step 4: simulate a successful verification code submitted
    state = reducer(state, confirmPendingNotificationMethod.succeeded({ success: true }));
    expect(state.pendingNotificationMethod).toBeUndefined();
    expect(state.notificationMethods.pendingId).toMatchObject({
      type: `VerifiedEmailMethod`,
      value: {
        id: `pendingId`,
        email: `foo@bar.com`,
      },
    });
  });
});

describe(`fetchProfileData`, () => {
  it(`.succeeded sets correctly massaged data on state slice`, () => {
    const apiData = mock.adminProfile({
      email: `blob@blob.com`,
      subscriptionStatus: `trialing`,
      verifiedNotificationMethods: [
        {
          type: `VerifiedEmailMethod`,
          value: { id: `verifiedMethod1`, email: `blob@blob.com` },
        },
        {
          type: `VerifiedTextMethod`,
          value: { id: `verifiedMethod2`, phoneNumber: `7` },
        },
      ],
      notifications: [
        mock.adminNotification({
          id: `notification1`,
          trigger: `unlockRequestSubmitted`,
          methodId: `verifiedMethod2`,
        }),
      ],
    });

    const nextState = reducer(makeState().admin, fetchProfileData.succeeded(apiData));

    expect(nextState.profileRequest).toEqual(
      Req.succeed({
        email: `blob@blob.com`,
        subscriptionStatus: `trialing`,
      }),
    );

    expect(nextState.notificationMethods).toEqual({
      verifiedMethod1: {
        type: `VerifiedEmailMethod`,
        value: { id: `verifiedMethod1`, email: `blob@blob.com` },
      },
      verifiedMethod2: {
        type: `VerifiedTextMethod`,
        value: { id: `verifiedMethod2`, phoneNumber: `7` },
      },
    });

    expect(nextState.notifications).toEqual({
      notification1: {
        editing: false,
        original: {
          id: `notification1`,
          trigger: `unlockRequestSubmitted`,
          methodId: `verifiedMethod2`,
        },
        draft: {
          id: `notification1`,
          trigger: `unlockRequestSubmitted`,
          methodId: `verifiedMethod2`,
        },
      },
    });
  });
});
