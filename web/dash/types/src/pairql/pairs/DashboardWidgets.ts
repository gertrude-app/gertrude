// auto-generated, do not edit
import type { ChildComputerStatus } from '../shared';

export namespace DashboardWidgets {
  export type Input = void;

  export interface Output {
    children: Array<{
      id: UUID;
      name: string;
      status: ChildComputerStatus;
      numDevices: number;
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
      icon?: string;
      html: string;
      learnMoreUrl?: string;
    };
  }
}
