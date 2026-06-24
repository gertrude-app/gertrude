// auto-generated, do not edit
export namespace IOSDeviceEvents {
  export interface Input {
    vendorId: UUID;
  }

  export interface Output {
    vendorId: UUID;
    modelName: string;
    deviceType: string;
    iosVersion: string;
    firstLaunch?: ISODateString;
    lastCheckin?: ISODateString;
    reachedOptOut: boolean;
    connectedAccount?: {
      parentId: UUID;
      parentEmail: string;
      childName: string;
    };
    prevVendorId?: UUID;
    nextVendorId?: UUID;
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
