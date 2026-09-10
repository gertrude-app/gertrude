// auto-generated, do not edit
import type { ClaimChildOption, MusicSubscriptionState } from '../shared';

export namespace GetMusicClaimData {
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
      childName: string;
      childId: UUID;
      deviceId: UUID;
      subscription?: MusicSubscriptionState;
    };
  }
}
