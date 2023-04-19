import type { Action } from '../lib/store';
import { Store } from '../lib/store';

// begin codegen
export type Request = {
  id: UUID;
  time: ISODateString;
  target: string;
  protocol: 'tcp' | 'udp' | 'other';
  searchableText: string;
  app: string;
};

export type AppState = {
  windowOpen: boolean;
  requests: Request[];
  filterText: string;
  tcpOnly: boolean;
  unlockRequest:
    | { case: 'failed'; error: string }
    | { case: 'idle' }
    | { case: 'loading' }
    | { case: 'succeeded' };
};

export type AppEvent =
  | { case: 'updateFilterText'; text: string }
  | { case: 'unlockRequestSubmitted'; ids: UUID[] }
  | { case: 'openWindow' }
  | { case: 'closeWindow' }
  | { case: 'toggleTcpOnly' }
  | { case: 'clearRequests' };
// end codegen

export type ViewState = {
  selectedRequests: UUID[];
  unlockRequestExplanation: string;
};

export type ViewAction =
  | { type: 'requestFailedTryAgainClicked' }
  | { type: 'explanationUpdated'; text: string }
  | { type: 'toggleRequestSelected'; id: UUID };

export class NetworkTrafficStore extends Store<
  AppState,
  AppEvent,
  ViewState,
  ViewAction
> {
  initializer(): AppState & ViewState {
    return {
      windowOpen: true,
      requests: [],
      filterText: ``,
      tcpOnly: true,
      unlockRequest: { case: `idle` },
      selectedRequests: [],
      unlockRequestExplanation: ``,
    };
  }

  reducer(
    state: AppState & ViewState,
    action: Action<AppState, ViewAction>,
  ): AppState & ViewState {
    switch (action.type) {
      default:
        return state;
    }
  }
}

export default new NetworkTrafficStore();
