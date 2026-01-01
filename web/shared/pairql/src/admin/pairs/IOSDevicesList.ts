// auto-generated, do not edit
export namespace IOSDevicesList {
  export interface Input {
    page: number;
    pageSize?: number;
  }

  export interface Output {
    devices: Array<{
      vendorId: UUID;
      deviceType: string;
      iosVersion: string;
      firstLaunch: ISODateString;
      eventCount: number;
      reachedOptOut: boolean;
    }>;
    totalCount: number;
    page: number;
    totalPages: number;
  }
}
