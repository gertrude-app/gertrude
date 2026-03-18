// auto-generated, do not edit
export namespace PromoteApp {
  export interface Input {
    bundleId: string;
    newApp?: {
      name: string;
      slug: string;
      categoryId?: UUID;
      launchable: boolean;
    };
    existingAppId?: UUID;
  }

  export interface Output {
    identifiedAppId: UUID;
    name: string;
  }
}
