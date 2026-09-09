// auto-generated, do not edit
export namespace GetPersonUnlockRequests {
  export interface Input {
    personId: UUID;
  }

  export interface Output {
    personId: UUID;
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
      numKeys: number;
    }>;
  }
}
