// auto-generated, do not edit
export namespace GetInstalledMacApps {
  export type Input = UUID;

  export type Output = Array<{
    bundleId: string;
    name: string;
    category?: string;
    identifiedAppSlug?: string;
    iconHash?: string;
  }>;
}
