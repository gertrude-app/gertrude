// auto-generated, do not edit
export namespace PodcastOverview {
  export type Input = void;

  export interface Output {
    totalInstalls: number;
    activePodcastUsers: number;
    iPhoneInstalls: number;
    iPadInstalls: number;
    statusBreakdown: {
      paid: number;
      complimentary: number;
      connected: number;
      trial: number;
      expired: number;
      iap: number;
    };
    recentInstalls: Array<{
      date: ISODateString;
      deviceType: string;
      status: string;
    }>;
  }
}
