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
  internetConnected: boolean;
  filterCommunicationConfirmed?: boolean;
}

export type AppEvent =
  | { case: 'requestSubmitted'; durationInSeconds: number; comment?: string }
  | { case: 'grantSuspensionClicked'; durationInSeconds: number }
  | { case: 'closeWindow' }
  | { case: 'requestFailedTryAgainClicked' }
  | { case: 'inactiveAccountRecheckClicked' }
  | { case: 'inactiveAccountDisconnectAppClicked' }
  | { case: 'noFilterCommunicationAdministrateClicked' };
// end codegen

export type ViewState = {
  comment: string;
  page: 'duration' | 'comment';
  duration:
    | { mode: `standard`; seconds: StandardDuration | null }
    | { mode: `custom`; seconds: number | null };
};

export type ViewAction =
  | { type: 'commentUpdated'; value: string }
  | { type: 'standardDurationClicked'; seconds: StandardDuration }
  | { type: 'customDurationUpdated'; seconds: number }
  | { type: 'chooseCustomDurationClicked' }
  | { type: 'closeCustomDurationDrawer' }
  | { type: 'nextFromDurationPageClicked' }
  | { type: 'backFromCommentPageClicked' };

export const STANDARD_DURATION_OPTIONS = [300, 600, 1200, 1800, 3600, 7200] as const;
export type StandardDuration = (typeof STANDARD_DURATION_OPTIONS)[number];

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
      page: `duration`,
      duration: {
        mode: `standard`,
        seconds: null,
      },
      internetConnected: true,
    };
  }

  reducer(
    state: AppState & ViewState,
    action: ActionOf<AppState, AppEvent, ViewAction>,
  ): AppState & ViewState {
    switch (action.type) {
      case `commentUpdated`:
        return { ...state, comment: action.value };
      case `standardDurationClicked`:
        return { ...state, duration: { mode: `standard`, seconds: action.seconds } };
      case `customDurationUpdated`:
        return { ...state, duration: { mode: `custom`, seconds: action.seconds } };
      case `chooseCustomDurationClicked`:
        return {
          ...state,
          duration: { mode: `custom`, seconds: state.duration.seconds ?? 90 * 60 },
        };
      case `closeCustomDurationDrawer`:
        return { ...state, duration: { mode: `standard`, seconds: null } };
      case `nextFromDurationPageClicked`:
        return { ...state, page: `comment` };
      case `backFromCommentPageClicked`:
        return { ...state, page: `duration` };
      case `receivedUpdatedAppState`:
        return { ...state, ...action.appState };
      case `appEventEmitted`:
        return state;
    }
  }
}

export default new RequestSuspensionStore();
