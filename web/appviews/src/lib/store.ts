import { useReducer, useEffect } from 'react';
import type React from 'react';

export type Store<State, Action, AppEvent, Props, InitArg = void> = {
  initializer: (arg: InitArg) => State;
  bind: (window: any, dispatch: React.Dispatch<Action>) => void;
  reducer: (state: State, action: Action) => State;
  emitter: (window: any) => (event: AppEvent) => unknown;
  selector: (
    state: State,
    dispatch: (action: Action) => unknown,
    emit: (event: AppEvent) => unknown,
  ) => Props;
};

export type Action<AppState, ViewAction = Record<never, never>> =
  | { type: 'receivedUpdatedAppState'; appState: AppState } & ViewAction;

export class BaseStore<AppState, AppEvent> {
  bind(window: any, dispatch: React.Dispatch<Action<AppState>>): void {
    window.updateAppState = (appState: AppState) => {
      dispatch({ type: `receivedUpdatedAppState`, appState });
    };
  }

  emitter(window: any): (event: AppEvent) => unknown {
    return (event: AppEvent) => {
      window.webkit.messageHandlers.appView.postMessage({
        message: JSON.stringify({ event }),
      });
    };
  }
}

export function containerize<AppState, Action, AppEvent, Props>(
  store: Store<AppState, Action, AppEvent, Props>,
  component: React.FC<Props>,
): React.FC {
  return () => {
    const [state, dispatch] = useReducer(store.reducer, void 0, store.initializer);

    useEffect(() => {
      store.bind(window, dispatch);
    }, []);

    const props = store.selector(state, dispatch, store.emitter(window));

    return component(props);
  };
}
