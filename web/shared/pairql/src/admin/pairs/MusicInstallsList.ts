// auto-generated, do not edit
export namespace MusicInstallsList {
  export interface Input {
    page: number;
    pageSize?: number;
  }

  export interface Output {
    installs: Array<{
      deviceId: UUID;
      deviceType: string;
      modelName: string;
      iosVersion: string;
      appVersion: string;
      firstLaunch: ISODateString;
      albumCount: number;
      status: string;
    }>;
    totalCount: number;
    page: number;
    totalPages: number;
  }
}
