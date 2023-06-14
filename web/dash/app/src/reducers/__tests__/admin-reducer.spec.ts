import { expect, it, test, describe } from 'vitest';
import type { State } from '../admin-reducer';
import { Req } from '../../lib/helpers';
import reducer, { initialState } from '../admin-reducer';
import * as mock from './mocks';

describe(`create new notification method flow`, () => {
  test(`happy path`, () => {
    let state: State = { ...initialState };

    // step 1: create a new pending notification method
    state = reducer(state, {
      type: `newNotificationMethodEvent`,
      event: { type: `createClicked` },
    });

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
    state = reducer(state, {
      type: `newNotificationMethodEvent`,
      event: { type: `emailAddressUpdated`, email: `foo@bar.com` },
    });

    expect(state.pendingNotificationMethod).toMatchObject({
      value: { email: `foo@bar.com` },
    });

    // step 3: simulate a successfull request to generate a code
    state = reducer(state, {
      type: `newNotificationMethodEvent`,
      event: { type: `createPendingMethodStarted` },
    });

    expect(state.pendingNotificationMethod).toMatchObject({
      sendCodeRequest: Req.ongoing(),
    });

    state = reducer(state, {
      type: `newNotificationMethodEvent`,
      event: { type: `createPendingMethodSucceeded`, methodId: `new-method-id` },
    });

    expect(state.pendingNotificationMethod).toMatchObject({
      sendCodeRequest: Req.succeed(`new-method-id`),
    });

    // step 4: simulate a successful verification code submitted
    state = reducer(state, {
      type: `newNotificationMethodEvent`,
      event: { type: `confirmPendingMethodStarted` },
    });

    expect(state.pendingNotificationMethod).toMatchObject({
      confirmationRequest: Req.ongoing(),
    });

    state = reducer(state, {
      type: `newNotificationMethodEvent`,
      event: { type: `confirmPendingMethodSucceeded` },
    });

    expect(state.pendingNotificationMethod).toBeUndefined();

    expect(state.notificationMethods[`new-method-id`]).toMatchObject({
      type: `VerifiedEmailMethod`,
      value: {
        id: `new-method-id`,
        email: `foo@bar.com`,
      },
    });
  });
});

describe(`receiving admin from api`, () => {
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

    const nextState = reducer(
      { ...initialState },
      {
        type: `receivedAdmin`,
        admin: apiData,
      },
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
        id: `notification1`,
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
