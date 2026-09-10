// auto-generated, do not edit
export namespace GetAccountUnlockRequestSummary {
  export type Input = void;

  export interface Output {
    totalCount: number;
    people: Array<{
      id: UUID;
      name: string;
      pendingCount: number;
      targets: string[];
    }>;
  }
}
