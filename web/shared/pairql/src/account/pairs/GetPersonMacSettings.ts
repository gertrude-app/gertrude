// auto-generated, do not edit
export namespace GetPersonMacSettings {
  export interface Input {
    personId: UUID;
  }

  export interface Output {
    keyloggingEnabled: boolean;
    showSuspensionActivity: boolean;
    screenshots: {
      enabled: boolean;
      resolution: number;
      frequency: number;
      canBeDisabled: boolean;
    };
    hasMacDevices: boolean;
  }
}
