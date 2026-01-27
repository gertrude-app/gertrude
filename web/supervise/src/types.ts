export interface DeviceInfo {
  id: string;
  name: string;
  model: string;
  osVersion: string;
}

export type OperationMode = `add` | `remove`;

export interface CodeEntryProps {
  code: string;
  onCodeChange: (code: string) => void;
  onSubmit: () => void;
  loading: boolean;
  error: string | null;
}

export interface PersonalizedConnectProps {
  childName: string;
  deviceType: string;
  modelName: string;
  iosVersion: string;
}

export interface DeviceMismatchProps {
  expectedModelName: string;
  connectedModelName: string;
  childName: string;
  onTryAgain: () => void;
}

export interface ChooseDirectionProps {
  device: DeviceInfo;
  onChooseAdd: () => void;
  onChooseRemove: () => void;
}

export interface DisableFindMyProps {
  onContinue: () => void;
}

export interface DisablePrivateRelayProps {
  onContinue: () => void;
}

export interface InProgressProps {
  mode: OperationMode;
  deviceName: string;
  running: boolean;
  progress: number;
  onStart: () => void;
}

export interface ConfirmRebootProps {
  onConfirm: () => void;
}

export interface CompleteProps {
  mode: OperationMode;
  deviceName: string;
  onDone: () => void;
}
