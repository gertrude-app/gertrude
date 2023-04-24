import { expect, beforeEach, test, describe } from 'vitest';
import type { Action, State } from '../blockedrequests-store';
import { BlockedRequestsStore } from '../blockedrequests-store';

describe(`BlockedRequestsStore.reducer()`, () => {
  let store: BlockedRequestsStore;
  beforeEach(() => {
    store = new BlockedRequestsStore();
  });

  test(`receivedUpdatedAppState action`, () => {
    const action: Action = {
      type: `receivedUpdatedAppState`,
      appState: { ...store.appState(), tcpOnly: false },
    };

    const nextState = store.reducer(store.initializer(), action);
    expect(nextState.tcpOnly).toBe(false);
  });

  test(`explanationUpdated action`, () => {
    const text = `New explanation`;
    const action: Action = { type: `explanationUpdated`, text };
    const nextState = store.reducer(store.initializer(), action);
    expect(nextState.unlockRequestExplanation).toBe(text);
  });

  test(`receive transition to createUnlockRequests success clears explanation`, () => {
    const prevState: State = {
      ...store.initializer(),
      unlockRequestExplanation: `please dad!`,
      createUnlockRequests: { case: `ongoing` },
    };

    const action: Action = {
      type: `receivedUpdatedAppState`,
      appState: {
        ...store.appState(),
        createUnlockRequests: { case: `succeeded` },
      },
    };

    const nextState = store.reducer(prevState, action);
    expect(nextState.unlockRequestExplanation).toEqual(``);
  });
});
