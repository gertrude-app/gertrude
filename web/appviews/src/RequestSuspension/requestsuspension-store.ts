import type { ActionOf } from '../lib/store';
import type { AdminAccountStatus } from '../lib/shared-types';
import { Store } from '../lib/store';

// begin codegen
export interface AppState {
  windowOpen: boolean;
  request:
    | { case: 'failed'; error: string }
    | { case: 'idle' }
    | { case: 'ongoing' }
    | { case: 'succeeded' };
  adminAccountStatus: AdminAccountStatus;
}

export type AppEvent =
  | { case: 'requestSubmitted'; durationInSeconds: number; comment?: string }
  | { case: 'closeWindow' }
  | { case: 'requestFailedTryAgainClicked' }
  | { case: 'inactiveAccountRecheckClicked' }
  | { case: 'inactiveAccountDisconnectAppClicked' };
// end codegen

export type ViewState = {
  comment: string;
  durationInSeconds?: number;
  overlay?: 'main' | 'customDuration';
  customDurationString: string;
};

export type ViewAction =
  | { type: 'commentUpdated'; value: string }
  | { type: 'customDurationUpdated'; value: string }
  | { type: 'standardDurationClicked'; minutes: number }
  | { type: 'overlayBackgroundClicked' }
  | { type: 'backFromCustomDurationClicked' }
  | { type: 'chooseCustomDurationClicked' }
  | { type: 'durationButtonClicked' }
  | { type: 'customDurationClicked' };

export type Action = ActionOf<AppState, AppEvent, ViewAction>;
export type State = AppState & ViewState;

export class RequestSuspensionStore extends Store<
  AppState,
  AppEvent,
  ViewState,
  ViewAction
> {
  initializer(): AppState & ViewState {
    return {
      adminAccountStatus: `active`,
      windowOpen: true,
      request: { case: `idle` },
      comment: ``,
      customDurationString: ``,
    };
  }

  reducer(
    state: AppState & ViewState,
    action: ActionOf<AppState, AppEvent, ViewAction>,
  ): AppState & ViewState {
    switch (action.type) {
      case `commentUpdated`:
        return { ...state, comment: action.value };
      case `backFromCustomDurationClicked`:
        return { ...state, overlay: `main` };
      case `overlayBackgroundClicked`:
        return { ...state, overlay: undefined };
      case `durationButtonClicked`:
        return { ...state, overlay: `main` };
      case `customDurationUpdated`:
        return { ...state, customDurationString: action.value };
      case `standardDurationClicked`:
        return {
          ...state,
          overlay: undefined,
          durationInSeconds: action.minutes * 60,
        };
      case `chooseCustomDurationClicked`:
        return {
          ...state,
          overlay: undefined,
          customDurationString: ``,
          durationInSeconds: Number(state.customDurationString) * 60,
        };
      case `customDurationClicked`:
        return { ...state, overlay: `customDuration` };
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `appEventEmitted`:
        return state;
    }
  }
}

export default new RequestSuspensionStore();
