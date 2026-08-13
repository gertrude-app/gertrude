// auto-generated, do not edit
export namespace GetPersonInstalledMacApps {
  export interface Input {
    personId: UUID;
  }

  export type Output = Array<{
    bundleId: string;
    name: string;
    category?: string;
    identifiedAppSlug?: string;
    iconHash?: string;
  }>;
}
