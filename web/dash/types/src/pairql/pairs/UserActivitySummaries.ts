// auto-generated, do not edit

export namespace UserActivitySummaries {
  export type Input = UUID;

  export interface Output {
    userName: string;
    days: Array<{
      date: ISODateString;
      numApproved: number;
      numFlagged: number;
      numTotal: number;
    }>;
  }
}
