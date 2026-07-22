// auto-generated, do not edit
export namespace MusicOverview {
  export type Input = void;

  export interface Output {
    totalInstalls: number;
    connectedMusicUsers: number;
    paidMusicFamilies: number;
    approvedAlbums: number;
    iPhoneInstalls: number;
    iPadInstalls: number;
    statusBreakdown: {
      paid: number;
      complimentary: number;
      connected: number;
      unclaimed: number;
    };
    recentInstalls: Array<{
      date: ISODateString;
      deviceType: string;
      status: string;
    }>;
  }
}
