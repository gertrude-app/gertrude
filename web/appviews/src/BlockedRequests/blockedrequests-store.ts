import type { AdminAccountStatus } from '../lib/shared-types';
import type { ActionOf } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export interface Request {
  id: UUID;
  time: ISODateString;
  target: string;
  protocol: `tcp` | `udp` | `other`;
  searchableText: string;
  app: string;
}

export interface AppState {
  windowOpen: boolean;
  selectedRequestIds: UUID[];
  requests: Request[];
  filterText: string;
  tcpOnly: boolean;
  createUnlockRequests:
    | { case: `failed`; error: string }
    | { case: `idle` }
    | { case: `ongoing` }
    | { case: `succeeded` };
  adminAccountStatus: AdminAccountStatus;
  filterCommunicationConfirmed?: boolean;
}

export type AppEvent =
  | { case: `filterTextUpdated`; text: string }
  | { case: `unlockRequestSubmitted`; comment?: string }
  | { case: `toggleRequestSelected`; id: UUID }
  | { case: `requestFailedTryAgainClicked` }
  | { case: `tcpOnlyToggled` }
  | { case: `clearRequestsClicked` }
  | { case: `closeWindow` }
  | { case: `inactiveAccountRecheckClicked` }
  | { case: `inactiveAccountDisconnectAppClicked` }
  | { case: `noFilterCommunicationAdministrateClicked` };
// end codegen

export type ViewState = {
  unlockRequestExplanation: string;
  requestsPaused: boolean;
};

export type ViewAction =
  | { type: `requestsPausedToggled` }
  | { type: `explanationUpdated`; text: string };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class BlockedRequestsStore extends Store<
  AppState,
  AppEvent,
  ViewState,
  ViewAction
> {
  appState(): AppState {
    return {
      adminAccountStatus: `active`,
      windowOpen: true,
      filterText: ``,
      selectedRequestIds: [],
      requests: [],
      tcpOnly: true,
      createUnlockRequests: { case: `idle` },
    };
  }

  viewState(): ViewState {
    return {
      unlockRequestExplanation: ``,
      requestsPaused: false,
    };
  }

  initializer(): State {
    return { ...this.appState(), ...this.viewState() };
  }

  reducer(state: State, action: Action): State {
    switch (action.type) {
      case `receivedUpdatedAppState`: {
        const reqSucceeded =
          state.createUnlockRequests.case === `ongoing` &&
          action.appState.createUnlockRequests.case === `succeeded`;
        if (state.requestsPaused) {
          action.appState.requests = state.requests;
        }
        return {
          ...state,
          ...action.appState,
          unlockRequestExplanation: reqSucceeded ? `` : state.unlockRequestExplanation,
        };
      }
      case `explanationUpdated`:
        return { ...state, unlockRequestExplanation: action.text };
      case `requestsPausedToggled`:
        return { ...state, requestsPaused: !state.requestsPaused };
      case `appEventEmitted`:
        return state;
    }
  }
}

export default new BlockedRequestsStore();
