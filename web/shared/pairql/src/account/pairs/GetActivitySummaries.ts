// auto-generated, do not edit
export namespace GetActivitySummaries {
  export interface Input {
    timeZone: string;
  }

  export type Output = Array<{
    date: ISODateString;
    numTotal: number;
    numDeleted: number;
    numFlagged: number;
  }>;
}
