export interface DeviceInfo {
  id: string;
  name: string;
  model: string;
  osVersion: string;
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
}

export interface DeviceMismatchProps {
  expectedModelName: string;
  connectedModelName: string;
  childName: string;
  onTryAgain: () => void;
}

export interface ConfirmDeviceProps {
  deviceName: string;
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
  onStart: () => void;
}

export type SupervisingProps = Record<string, never>;

export interface SwipeToUpgradeProps {
  onContinue: () => void;
}

export interface ConfirmSupervisionProps {
  onYes: () => void;
  onNo: () => void;
}

export type ErrorType = `findMyEnabled` | `invokeFailed` | `userReportedNo`;

export interface ErrorProps {
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
