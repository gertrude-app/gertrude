// auto-generated, do not edit
export namespace IOSOverview {
  export type Input = void;

  export interface Output {
    adjustedLaunches: number;
    parentFalseStarts: number;
    totalSuccess: number;
    standardSuccess: number;
    supervisedSuccess: number;
    stuckIn18PlusPath: number;
    successRate: number;
    recentInstalls: Array<{
      date: ISODateString;
      status: string;
      deviceType: string;
    }>;
  }
}
