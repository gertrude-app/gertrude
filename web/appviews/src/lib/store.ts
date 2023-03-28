import { useReducer, useEffect } from 'react';
import type React from 'react';

export type Action<AppState, ViewAction> =
  | { type: 'receivedUpdatedAppState'; appState: AppState }
  | ViewAction;

export type PropsOf<AppState, ViewState, AppEvent, ViewAction> = AppState &
  ViewState & {
    emit: (event: AppEvent) => unknown;
    dispatch: (action: ViewAction) => unknown;
  };

export abstract class Store<AppState, AppEvent, ViewState, ViewAction> {
  bind(window: any, dispatch: React.Dispatch<Action<AppState, ViewAction>>): void {
    window.updateAppState = (appState: AppState) => {
      dispatch({ type: `receivedUpdatedAppState`, appState });
    };
  }

  emitter(window: any): (event: AppEvent) => unknown {
    return (event: AppEvent) => {
      window.webkit.messageHandlers.appView.postMessage(JSON.stringify(event));
    };
  }

  abstract initializer(): AppState & ViewState;

  abstract reducer(
    state: AppState & ViewState,
    action: Action<AppState, ViewAction>,
  ): AppState & ViewState;
}

export function containerize<AppState, AppEvent, ViewState, ViewAction>(
  store: Store<AppState, AppEvent, ViewState, ViewAction>,
  component: React.FC<PropsOf<AppState, ViewState, AppEvent, ViewAction>>,
): React.FC {
  return () => {
    const [state, dispatch] = useReducer(store.reducer, undefined, store.initializer);

    useEffect(() => {
      store.bind(window, dispatch);
    }, []);

    const props = {
      ...state,
      emit: store.emitter(window),
      dispatch,
    };

    return component(props);
  };
}
