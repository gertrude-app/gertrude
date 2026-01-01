// auto-generated, do not edit
export namespace IOSDeviceJourney {
  export interface Input {
    vendorId: UUID;
  }

  export interface Output {
    vendorId: UUID;
    deviceType: string;
    iosVersion: string;
    firstLaunch?: ISODateString;
    reachedOptOut: boolean;
    events: Array<{
      id: string;
      eventId: string;
      label: string;
      detail?: string;
      createdAt: ISODateString;
      elapsedSeconds?: number;
    }>;
  }
}
