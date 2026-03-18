// auto-generated, do not edit
export namespace PodcastInstallDetail {
  export interface Input {
    deviceId: UUID;
  }

  export interface Output {
    deviceId: UUID;
    deviceType: string;
    iosVersion: string;
    appVersion: string;
    firstLaunch?: ISODateString;
    isPaid: boolean;
    events: Array<{
      id: string;
      eventId: string;
      kind: string;
      label: string;
      detail?: string;
      createdAt: ISODateString;
      elapsedSeconds?: number;
    }>;
    subscribedFeeds: Array<{
      url: string;
      subscribedAt: ISODateString;
    }>;
  }
}
