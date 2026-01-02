import React from 'react';
import type { DeviceInfo, Frame, OperationMode, SuperviseApi } from './types';

export interface SuperviseContextValue {
  api: SuperviseApi;
  device: DeviceInfo | null;
  setDevice: (device: DeviceInfo | null) => void;
  mode: OperationMode;
  setMode: (mode: OperationMode) => void;
  currentFrame: Frame;
  goToFrame: (frame: Frame) => void;
  error: string | null;
  setError: (error: string | null) => void;
}

const SuperviseContext = React.createContext<SuperviseContextValue | null>(null);

export const useSupervise = (): SuperviseContextValue => {
  const ctx = React.useContext(SuperviseContext);
  if (!ctx) throw new Error(`useSupervise must be used within SuperviseProvider`);
  return ctx;
};

export default SuperviseContext;
