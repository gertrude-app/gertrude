// auto-generated, do not edit
import type { AmSubscriptionState, ClaimChildOption } from '../shared';

export namespace GetAmClaimData {
  export interface Input {
    code: number;
  }

  export interface Output {
    children: ClaimChildOption[];
    modelName: string;
    deviceType: string;
    iosVersion: string;
    resumeStep?: {
      case: 'done';
      amSubscription: AmSubscriptionState;
      childName: string;
      childId: UUID;
      deviceId: UUID;
    };
  }
}
