// auto-generated, do not edit
import type { AmSubscriptionState, IOSDeviceChildAssignment } from '../shared';

export namespace ClaimAmDevice {
  export interface Input {
    code: number;
    child: IOSDeviceChildAssignment;
  }

  export interface Output {
    childName: string;
    modelName: string;
    iosVersion: string;
    code: number;
    subscription: AmSubscriptionState;
  }
}
