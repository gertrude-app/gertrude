// auto-generated, do not edit
export namespace GetSecurityEvents {
  export type Input = void;

  export type Output = Array<
    | {
        case: 'macApp';
        id: UUID;
        personId: UUID;
        personName: string;
        deviceId: UUID;
        deviceName: string;
        title: string;
        detail?: string;
        explanation: string;
        severity: 'high' | 'medium' | 'low';
        createdAt: ISODateString;
      }
    | {
        case: 'account';
        id: UUID;
        title: string;
        detail?: string;
        explanation: string;
        severity: 'high' | 'medium' | 'low';
        ipAddress?: string;
        createdAt: ISODateString;
      }
  >;
}
