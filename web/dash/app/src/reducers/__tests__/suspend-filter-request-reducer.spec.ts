import { expect, test, describe } from 'vitest';
import reducer, { initialState } from '../suspend-filter-request-reducer';

describe(`suspendFilterRequestReducer()`, () => {
  const apiRequest = {
    id: `sfr-1`,
    deviceId: `d-1`,
    status: `pending` as const,
    userName: `Little Jimmy`,
    createdAt: new Date().toISOString(),
    requestedDurationInSeconds: 60 * 10,
    extraMonitoringOptions: {},
  };

  test(`initializes granted duration with requested basic duration`, () => {
    const nextState = reducer(
      { ...initialState },
      { type: `receivedRequest`, request: apiRequest },
    );

    expect(nextState.request).toEqual(apiRequest);
    expect(nextState.grantedDurationInSeconds).toBe(`600`);
  });

  test(`initializes granted duration with requested custom duration`, () => {
    const customDurationApiRequest = {
      ...apiRequest,
      requestedDurationInSeconds: 60 * 17, // <-- 17 minutes
    };

    const nextState = reducer(
      { ...initialState },
      { type: `receivedRequest`, request: customDurationApiRequest },
    );

    expect(nextState).toMatchObject({
      grantedDurationInSeconds: `custom`,
      grantedCustomDurationInMinutes: `17`,
    });
  });
});
