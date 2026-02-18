// auto-generated, do not edit
export namespace SubscriptionsOverview {
  export type Input = void;

  export interface Output {
    monthlyRevenue: number;
    annualRevenue: number;
    fullPlanCount: number;
    fullPlanAnnualRevenue: number;
    lightPlanCount: number;
    lightPlanAnnualRevenue: number;
    trialingCount: number;
    totalAccounts: number;
    recentSignups: Array<{
      date: ISODateString;
      email: string;
      planCase: string;
      hasCompletedSupervision: boolean;
    }>;
  }
}
