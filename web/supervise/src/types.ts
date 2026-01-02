export interface DeviceInfo {
  id: string;
  name: string;
  model: string;
  osVersion: string;
}

export interface SuperviseApi {
  getConnectedDevice: () => Promise<DeviceInfo>;
  performOperation: (mode: `add` | `remove`) => Promise<void>;
  closeWindow: () => void;
}

export type OperationMode = `add` | `remove`;

export type ErrorType = `no-device` | `find-my-enabled` | `disconnected` | `unknown`;

export type Frame =
  | `connect-device`
  | `choose-direction`
  | `disable-find-my`
  | `disable-private-relay`
  | `in-progress`
  | `confirm-reboot`
  | `complete`;
