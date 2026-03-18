// auto-generated, do not edit
export namespace PodcastInstallsList {
  export interface Input {
    page: number;
    pageSize?: number;
  }

  export interface Output {
    installs: Array<{
      deviceId: UUID;
      deviceType: string;
      iosVersion: string;
      appVersion: string;
      firstLaunch: ISODateString;
      eventCount: number;
      feedCount: number;
      isPaid: boolean;
    }>;
    totalCount: number;
    page: number;
    totalPages: number;
  }
}
