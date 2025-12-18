// auto-generated, do not edit
export namespace MacOverview {
  export type Input = void;

  export interface Output {
    annualRevenue: number;
    payingParents: number;
    activeParents: number;
    childrenOfActiveParents: number;
    allTimeChildren: number;
    allTimeAppInstallations: number;
    recentSignups: Array<{
      date: ISODateString;
      status: string;
      email: string;
    }>;
  }
}
