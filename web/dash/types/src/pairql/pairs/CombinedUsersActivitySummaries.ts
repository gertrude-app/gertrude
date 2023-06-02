// auto-generated, do not edit

export namespace CombinedUsersActivitySummaries {
  export type Input = Array<{
    start: string;
    end: string;
  }>;

  export type Output = Array<{
    date: ISODateString;
    numApproved: number;
    totalItems: number;
  }>;
}
