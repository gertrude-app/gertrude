// auto-generated, do not edit
export namespace FamilyActivitySummaries {
  export interface Input {
    timeZone: string;
  }

  export type Output = Array<{
    date: ISODateString;
    numApproved: number;
    numFlagged: number;
    numTotal: number;
  }>;
}
