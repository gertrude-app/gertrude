// auto-generated, do not edit
export namespace SubscriptionsOverview {
  export type Input = void;

  export interface Output {
    monthlyRevenue: number;
    annualRevenue: number;
    monthlySubscriptionRevenue: Array<{
      month: string;
      centsCollected: number;
      fullPlanCents: number;
      lightPlanCents: number;
      otherCents: number;
      paidInvoices: number;
    }>;
    fullPlanCount: number;
    fullPlanAnnualRevenue: number;
    lightPlanCount: number;
    lightPlanAnnualRevenue: number;
    trialingCount: number;
    totalAccounts: number;
    recentSignups: Array<{
      date: ISODateString;
      email: string;
      engagement: string;
    }>;
  }
}
