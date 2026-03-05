export interface DeviceInfo {
  id: string;
  name: string;
  model: string;
  osVersion: string;
}

export interface ITunesRequiredProps {
  deviceType: string;
  onContinue: () => void;
}

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
  isWindows?: boolean;
}

export interface DeviceMismatchProps {
  expectedModelName: string;
  connectedModelName: string;
  childName: string;
  deviceType: string;
  onTryAgain: () => void;
}

export interface ConfirmDeviceProps {
  deviceName: string;
  deviceType: string;
  iosVersion: string;
  onConfirm: () => void;
  onReject: () => void;
}

export interface DisableFindMyProps {
  childName: string;
  deviceType: string;
  onContinue: () => void;
}

export interface DisablePrivateRelayProps {
  onContinue: () => void;
}

export interface GetReadyProps {
  deviceType: string;
  onStart: () => void;
}

export interface SupervisingProps {
  deviceType: string;
}

export interface SwipeToUpgradeProps {
  deviceType: string;
  onContinue: () => void;
}

export interface ConfirmSupervisionProps {
  deviceType: string;
  onYes: () => void;
  onNo: () => void;
}

export type ErrorType = `findMyEnabled` | `invokeFailed` | `userReportedNo`;

export interface ErrorProps {
  deviceType: string;
  errorType: ErrorType;
  errorMessage?: string;
  onRetry: () => void;
  onContactSupport: () => void;
}

export interface CompleteProps {
  childName: string;
  deviceType: string;
  onDone: () => void;
}
