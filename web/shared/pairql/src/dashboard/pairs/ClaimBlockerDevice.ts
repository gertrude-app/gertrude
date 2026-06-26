// auto-generated, do not edit
import type { IOSDeviceChildAssignment } from '../shared';

export namespace ClaimBlockerDevice {
  export interface Input {
    code: number;
    child: IOSDeviceChildAssignment;
  }

  export interface Output {
    childName: string;
    modelName: string;
    iosVersion: string;
    code: number;
    childId: UUID;
    deviceId: UUID;
  }
}
