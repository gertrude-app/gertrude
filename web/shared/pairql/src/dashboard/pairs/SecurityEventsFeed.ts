// auto-generated, do not edit
export namespace SecurityEventsFeed {
  export type Input = void;

  export type Output = Array<
    | {
        case: `child`;
        id: UUID;
        childId: UUID;
        childName: string;
        deviceId: UUID;
        deviceName: string;
        event: string;
        detail?: string;
        explanation: string;
        createdAt: ISODateString;
      }
    | {
        case: `admin`;
        id: UUID;
        event: string;
        detail?: string;
        explanation: string;
        ipAddress?: string;
        createdAt: ISODateString;
      }
  >;
}
