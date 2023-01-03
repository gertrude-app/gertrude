// auto-generated, do not edit

export namespace GetDashboardWidgets {
  export type Input = void;

  export interface Output {
    users: Array<{
      id: UUID;
      userName: string;
      isOnline: boolean;
    }>;
    userActivitySummaries: Array<{
      id: UUID;
      name: string;
      numUnreviewed: number;
      numReviewed: number;
    }>;
    unlockRequests: Array<{
      id: UUID;
      userId: UUID;
      userName: string;
      target: string;
      comment?: string;
      createdAt: ISODateString;
    }>;
    recentScreenshots: Array<{
      id: UUID;
      userName: string;
      url: string;
      createdAt: ISODateString;
    }>;
  }
}
