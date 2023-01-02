export interface SuccessOutput {
  success: boolean;
}

export enum DeviceModelFamily {
  macBookAir,
  macBookPro,
  mini,
  iMac,
  studio,
  pro,
  unknown,
}

export enum AdminNotificationTrigger {
  unlockRequestSubmitted,
  suspendFilterRequestSubmitted,
}

export enum ClientAuth {
  none,
  user,
  admin,
}

export enum RequestStatus {
  pending,
  accepted,
  rejected,
}
