// auto-generated, do not edit
import type { ClaimChildOption } from '../shared';

export namespace GetIOSDeviceClaimData {
  export interface Input {
    code: number;
  }

  export interface Output {
    children: ClaimChildOption[];
    modelName: string;
    deviceType: string;
    iosVersion: string;
    resumeStep?: 'payment' | 'downloadHelper' | 'done';
  }
}
