// auto-generated, do not edit

export namespace UserActivitySummaries {
  export interface Input {
    userId: UUID;
    dateRanges: Array<{
      start: string;
      end: string;
    }>;
  }

  export interface Output {
    userName: string;
    days: Array<{
      date: ISODateString;
      numApproved: number;
      totalItems: number;
    }>;
  }
}
