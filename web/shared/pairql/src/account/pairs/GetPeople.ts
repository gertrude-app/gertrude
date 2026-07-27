// auto-generated, do not edit
export namespace GetPeople {
  export type Input = void;

  export type Output = Array<{
    id: UUID;
    name: string;
    devices: Array<
      | {
          case: 'mac';
          id: UUID;
          name?: string;
          macOSVersion?: string;
          modelName: string;
          modelIdentifier: string;
          online: boolean;
        }
      | {
          case: 'ios';
          id: UUID;
          type: 'iphone' | 'ipad';
          iOSVersion: string;
          modelName: string;
          modelIdentifier: string;
        }
    >;
    screenshot?: {
      url: string;
      createdAt: ISODateString;
    };
  }>;
}
