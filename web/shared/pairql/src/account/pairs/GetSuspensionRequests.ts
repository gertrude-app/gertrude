// auto-generated, do not edit
export namespace GetSuspensionRequests {
  export type Input = void;

  export type Output = Array<{
    id: UUID;
    personId: UUID;
    personName: string;
    deviceName?: string;
    requestedDurationInSeconds: number;
    reason?: string;
    extraMonitoringOptions: {
      [key: string]: string;
    };
    createdAt: ISODateString;
  }>;
}
