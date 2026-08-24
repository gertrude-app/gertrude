export type MacDevice = {
  id: string;
  type: `mac`;
  name?: string;
  modelName: string;
  modelIdentifier: string;
  macOSVersion?: string;
  people: Array<{
    id: string;
    name: string;
  }>;
};

export type ConnectedIOSApp = `blocker` | `podcasts` | `music`;

export type IOSDeviceSupervisionStatus =
  `pendingClaim` | `claimed` | `supervised` | `complete`;

export type MobileDevice = {
  id: string;
  type: `iphone` | `ipad`;
  modelName: string;
  modelIdentifier: string;
  iOSVersion: string;
  person: {
    id: string;
    name: string;
  };
  connectedApps: ConnectedIOSApp[];
  supervisionStatus?: IOSDeviceSupervisionStatus;
};

export type DevicesPageData = {
  macs: MacDevice[];
  mobileDevices: MobileDevice[];
};
