// auto-generated, do not edit
export namespace ChildActivitySummaries {
  export interface Input {
    childId: UUID;
    timeZone: string;
  }

  export interface Output {
    childName: string;
    days: Array<{
      date: ISODateString;
      numApproved: number;
      numFlagged: number;
      numTotal: number;
    }>;
  }
}
