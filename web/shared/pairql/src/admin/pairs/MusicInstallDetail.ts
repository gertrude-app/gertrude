// auto-generated, do not edit
export namespace MusicInstallDetail {
  export interface Input {
    deviceId: UUID;
  }

  export interface Output {
    deviceId: UUID;
    deviceType: string;
    iosVersion: string;
    appVersion: string;
    firstLaunch: ISODateString;
    status: string;
    connectedAccount?: {
      parentId: UUID;
      parentEmail: string;
      childName: string;
    };
    events: Array<{
      id: string;
      eventId: string;
      level: string;
      domain?: string;
      label: string;
      detail?: string;
      createdAt: ISODateString;
      elapsedSeconds?: number;
    }>;
    approvedAlbums: Array<{
      title: string;
      artistName: string;
      artworkUrl?: string;
      trackCount?: number;
      approvedAt: ISODateString;
    }>;
  }
}
