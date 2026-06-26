// auto-generated, do not edit
export namespace GetPersonActivitySummaries {
  export interface Input {
    personId: UUID;
    timeZone: string;
  }

  export interface Output {
    personName: string;
    days: Array<{
      date: ISODateString;
      numTotal: number;
      numDeleted: number;
      numFlagged: number;
    }>;
  }
}
