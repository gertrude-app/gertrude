// auto-generated, do not edit
export namespace GetIOSDeviceClaimData {
  export interface Input {
    code: number;
  }

  export interface Output {
    children: Array<{
      id: UUID;
      name: string;
    }>;
    modelName: string;
    deviceType: string;
    iosVersion: string;
    resumeStep?: 'payment' | 'downloadHelper' | 'done';
  }
}
