import { expect, beforeEach, test, describe } from 'vitest';
import type { Action, State, Request } from '../blockedrequests-store';
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

  test(`no new requests added to state when paused`, () => {
    const prevState: State = { ...store.initializer() };

    let action: Action = {
      type: `receivedUpdatedAppState`,
      appState: {
        ...store.appState(),
        requests: [request(`2`, `newsite.com`), request(`1`, `example.com`)],
      },
    };

    let nextState = store.reducer(prevState, action);
    expect(nextState.requests.map((r) => r.id)).toEqual([`2`, `1`]);

    action = { type: `requestsPausedToggled` };
    nextState = store.reducer(nextState, action);
    expect(nextState.requestsPaused).toBe(true);

    action = {
      type: `receivedUpdatedAppState`,
      appState: {
        ...store.appState(),
        requests: [
          request(`3`, `happyfish.com`), // <-- came in while paused
          request(`2`, `newsite.com`),
          request(`1`, `example.com`),
        ],
      },
    };
    expect(nextState.requests.map((r) => r.id)).toEqual([`2`, `1`]);
  });
});

function request(id: string, target: string): Request {
  return {
    id,
    time: new Date().toISOString(),
    target,
    protocol: `tcp`,
    searchableText: ``,
    app: `com.widget.app`,
  };
}
