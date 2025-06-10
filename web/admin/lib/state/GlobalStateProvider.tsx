'use client';

import { createContext, useReducer } from 'react';
import type { Action, State } from './store';
import { initialState, reducer } from './store';

export const GlobalStateContext = createContext<{
  state: State;
  dispatch: React.Dispatch<Action>;
}>({
  state: initialState,
  dispatch: () => console.log(`Provider not found`), // eslint-disable-line no-console
});

const GlobalStateProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(reducer, initialState);
  const contextValue = { state, dispatch };
  return (
    <GlobalStateContext.Provider value={contextValue}>
      {children}
    </GlobalStateContext.Provider>
  );
};

export default GlobalStateProvider;
