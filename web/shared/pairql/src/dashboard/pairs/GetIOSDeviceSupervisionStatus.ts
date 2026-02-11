// auto-generated, do not edit
export namespace GetIOSDeviceSupervisionStatus {
  export interface Input {
    code: number;
  }

  export interface Output {
    deviceId: UUID;
    childId: UUID;
    childName: string;
    modelName: string;
    deviceType: string;
    iosVersion: string;
    supervisionStatus: `awaitingSupervision` | `supervised`;
    requiresPayment: boolean;
  }
}
