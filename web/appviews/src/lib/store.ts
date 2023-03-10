import { useReducer, useEffect } from 'react';
import type React from 'react';

export type Action<AppState, ViewAction = never> =
  | { type: 'receivedUpdatedAppState'; appState: AppState }
  | ViewAction;

export abstract class Store<
  AppState,
  AppEvent,
  Props,
  InitArg = void,
  ViewAction = never,
  ViewState = Record<never, never>,
> {
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

  abstract initializer(arg: InitArg): AppState & ViewState;

  abstract reducer(
    state: AppState & ViewState,
    action: Action<AppState, ViewAction>,
  ): AppState & ViewState;

  abstract selector(
    state: AppState & ViewState,
    emit: (event: AppEvent) => unknown,
    dispatch: (action: ViewAction) => unknown,
  ): Props;
}

export function containerize<AppState, AppEvent, Props>(
  store: Store<AppState, AppEvent, Props>,
  component: React.FC<Props>,
): React.FC {
  return () => {
    const [state, dispatch] = useReducer(store.reducer, void 0, store.initializer);

    useEffect(() => {
      store.bind(window, dispatch);
    }, []);

    const props = store.selector(state, store.emitter(window), dispatch);

    return component(props);
  };
}
