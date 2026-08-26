// auto-generated, do not edit
export namespace GetIosDeviceSettings {
  export interface Input {
    deviceId: UUID;
  }

  export interface Output {
    deviceId: UUID;
    personId: UUID;
    deviceName: string;
    modelIdentifier: string;
    iosVersion: string;
    blocker?: {
      allBlockGroups: Array<{
        id: UUID;
        name: string;
        description: string;
        longDescription: string;
        optIn: boolean;
      }>;
      enabledBlockGroupIds: UUID[];
      isSupervised: boolean;
      profileSettings: {
        preventProtectionRemoval: boolean;
        allowDeletingApps: boolean;
        allowFactoryReset: boolean;
        allowInstallingApps: boolean;
      };
    };
    podcasts?: {
      subscription:
        | {
            case: 'active';
            expiresAt: ISODateString;
          }
        | {
            case: 'fullTrial';
            expiresAt: ISODateString;
          }
        | {
            case: 'amTrial';
            expiresAt: ISODateString;
          }
        | {
            case: 'unpaid';
            remediationUrl?: string;
          }
        | {
            case: 'legacyGrandfathered';
            accessEndsAt: ISODateString;
            showMigrationNag: boolean;
            migrationUrl?: string;
          }
        | {
            case: 'legacyExpired';
            paidAt: ISODateString;
            remediationUrl?: string;
          }
        | {
            case: 'complimentary';
          };
    };
    music?: {
      requiresPayment: boolean;
    };
  }
}
