// auto-generated, do not edit

export namespace GetIdentifiedApps {
  export type Input = void;

  export type Output = Array<{
    id: UUID;
    name: string;
    slug: string;
    selectable: boolean;
    bundleIds: Array<{
      id: UUID;
      bundleId: string;
    }>;
    category?: {
      id: UUID;
      name: string;
      slug: string;
    };
  }>;
}
