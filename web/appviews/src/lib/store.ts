import { useReducer, useEffect } from 'react';
import type React from 'react';

export type ActionOf<AppState, AppEvent, ViewAction> =
  | { type: `receivedUpdatedAppState`; appState: AppState }
  | { type: `appEventEmitted`; event: AppEvent }
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
      console.log(new Date().toISOString(), `received updated app state:`, appState); // eslint-disable-line
    };
    window.updateColorScheme = (colorScheme: `light` | `dark`) => {
      try {
        document.body.classList.remove(`light`, `dark`);
        document.body.classList.add(colorScheme);
        // eslint-disable-next-line
        console.log(
          new Date().toISOString(),
          `received updated color scheme:`,
          colorScheme,
        );
      } catch {
        // ¯\_(ツ)_/¯
      }
    };
  }

  emitter(
    window: any,
    dispatch: React.Dispatch<ActionOf<AppState, AppEvent, ViewAction>>,
  ): (event: AppEvent | `__APPVIEW_READY__`) => unknown {
    return (event: AppEvent | `__APPVIEW_READY__`) => {
      if (event === `__APPVIEW_READY__`) {
        window.webkit.messageHandlers.appView.postMessage(event);
        console.log(new Date().toISOString(), `emit: __APPVIEW_READY__`); // eslint-disable-line
      } else {
        dispatch({ type: `appEventEmitted`, event });
        window.webkit.messageHandlers.appView.postMessage(JSON.stringify(event));
        console.log(new Date().toISOString(), `emit app event:`, event); // eslint-disable-line
      }
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

    const emit = store.emitter(window, dispatch);

    useEffect(() => {
      store.bind(window, dispatch);
      emit(`__APPVIEW_READY__`);
    }, []); // eslint-disable-line

    const props = { ...state, emit, dispatch };
    return component(props);
  };
}
