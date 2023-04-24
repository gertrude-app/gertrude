import { useReducer, useEffect } from 'react';
import type React from 'react';

export type ActionOf<AppState, AppEvent, ViewAction> =
  | { type: 'receivedUpdatedAppState'; appState: AppState }
  | { type: 'appEventEmitted'; event: AppEvent }
  | ViewAction;

export type PropsOf<AppState, ViewState, AppEvent, ViewAction> = AppState &
  ViewState & {
    emit: (event: AppEvent) => unknown;
    dispatch: (action: ViewAction) => unknown;
  };

export abstract class Store<AppState, AppEvent, ViewState, ViewAction> {
  bind(
    window: any,
    dispatch: React.Dispatch<ActionOf<AppState, AppEvent, ViewAction>>,
  ): void {
    window.updateAppState = (appState: AppState) => {
      dispatch({ type: `receivedUpdatedAppState`, appState });
    };
  }

  emitter(
    window: any,
    dispatch: React.Dispatch<ActionOf<AppState, AppEvent, ViewAction>>,
  ): (event: AppEvent) => unknown {
    return (event: AppEvent) => {
      dispatch({ type: `appEventEmitted`, event });
      window.webkit.messageHandlers.appView.postMessage(JSON.stringify(event));
    };
  }

  abstract initializer(): AppState & ViewState;

  abstract reducer(
    state: AppState & ViewState,
    action: ActionOf<AppState, AppEvent, ViewAction>,
  ): AppState & ViewState;
}

export function containerize<AppState, AppEvent, ViewState, ViewAction>(
  store: Store<AppState, AppEvent, ViewState, ViewAction>,
  component: React.FC<PropsOf<AppState, ViewState, AppEvent, ViewAction>>,
): React.FC {
  return () => {
    const [state, dispatch] = useReducer(
      store.reducer.bind(store),
      undefined,
      store.initializer.bind(store),
    );

    useEffect(() => {
      store.bind(window, dispatch);
    }, []);

    const props = {
      ...state,
      emit: store.emitter(window, dispatch),
      dispatch,
    };

    return component(props);
  };
}
