// auto-generated, do not edit
export namespace CohortAnalysis {
  export type Input = void;

  export interface Output {
    generatedAt: ISODateString;
    cohorts: Array<{
      month: string;
      verifiedSignups: number;
      paidIntentCount: number;
      paidIntentEverPaidCount: number;
      paidIntentPayingCount: number;
      freeIosCount: number;
      freeIosProtectedCount: number;
      protectedCount: number;
      macProtectedCount: number;
      iosProtectedCount: number;
      everPaidCount: number;
      currentlyPayingCount: number;
    }>;
  }
}
