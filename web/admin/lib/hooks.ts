import { useContext } from 'react';
import type { Action, State } from './state/store';
import type React from 'react';
import { GlobalStateContext } from './state/GlobalStateProvider';

export function useGlobalState(): {
  state: State;
  dispatch: React.Dispatch<Action>;
} {
  return useContext(GlobalStateContext);
}
