// auto-generated, do not edit
export namespace GetPersonUnlockRequests {
  export interface Input {
    personId: UUID;
  }

  export interface Output {
    personName: string;
    requests: Array<{
      id: UUID;
      url?: string;
      domain?: string;
      ipAddress?: string;
      requestComment?: string;
      appName?: string;
      appSlug?: string;
      appBundleId?: string;
      appIconHash?: string;
      appCategories: string[];
      createdAt: ISODateString;
    }>;
    keychains: Array<{
      id: UUID;
      name: string;
      schedule?: {
        type: 'active' | 'inactive';
        days: {
          sunday: boolean;
          monday: boolean;
          tuesday: boolean;
          wednesday: boolean;
          thursday: boolean;
          friday: boolean;
          saturday: boolean;
        };
        startTime: {
          hour: number;
          minute: number;
        };
        endTime: {
          hour: number;
          minute: number;
        };
      };
      otherPeople: string[];
    }>;
    defaultKeychainId?: UUID;
  }
}
