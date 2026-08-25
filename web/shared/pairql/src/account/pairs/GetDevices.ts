// auto-generated, do not edit
export namespace GetDevices {
  export type Input = void;

  export interface Output {
    macs: Array<{
      id: UUID;
      name?: string;
      modelName: string;
      modelIdentifier: string;
      macOSVersion?: string;
      people: Array<{
        id: UUID;
        name: string;
      }>;
    }>;
    mobileDevices: Array<{
      id: UUID;
      type: 'iphone' | 'ipad';
      modelName: string;
      modelIdentifier: string;
      iOSVersion: string;
      person: {
        id: UUID;
        name: string;
      };
      connectedApps: Array<'blocker' | 'podcasts' | 'music'>;
      supervisionStatus?: 'pendingClaim' | 'claimed' | 'supervised' | 'complete';
    }>;
  }
}
