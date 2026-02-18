// auto-generated, do not edit
import type { ChildComputerStatus } from '../shared';

export namespace DashboardWidgets_v2 {
  export type Input = void;

  export interface Output {
    children: Array<{
      id: UUID;
      name: string;
      devices: Array<{
        platform: `mac` | `ios`;
        deviceName: string;
        macStatus?: ChildComputerStatus;
        iosStatus?: `setupComplete` | `pendingSetup`;
      }>;
    }>;
    childActivitySummaries: Array<{
      id: UUID;
      name: string;
      numUnreviewed: number;
      numReviewed: number;
    }>;
    unlockRequests: Array<{
      id: UUID;
      childId: UUID;
      childName: string;
      target: string;
      comment?: string;
      createdAt: ISODateString;
    }>;
    recentScreenshots: Array<{
      id: UUID;
      childName: string;
      url: string;
      createdAt: ISODateString;
    }>;
    numParentNotifications: number;
    announcement?: {
      id: UUID;
      kind: `news` | `warning`;
      icon?: string;
      html: string;
      learnMoreUrl?: string;
    };
    pendingIOSDevices: Array<{
      childName: string;
      modelName: string;
      claimCode: number;
    }>;
  }
}
