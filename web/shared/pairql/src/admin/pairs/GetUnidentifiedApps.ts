// auto-generated, do not edit
export namespace GetUnidentifiedApps {
  export interface Input {
    threshold: number;
    limit: number;
  }

  export interface Output {
    apps: Array<{
      id: UUID;
      bundleId: string;
      bundleName?: string;
      localizedName?: string;
      count: number;
      launchable?: boolean;
    }>;
    totalAboveThreshold: number;
  }
}
