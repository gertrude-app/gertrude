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
      mediumPlanCents: number;
      lightPlanCents: number;
      otherCents: number;
      paidInvoices: number;
    }>;
    fullPlanCount: number;
    fullPlanAnnualRevenue: number;
    mediumPlanCount: number;
    mediumPlanAnnualRevenue: number;
    lightPlanCount: number;
    lightPlanAnnualRevenue: number;
    trialingCount: number;
    protectedChildren: number;
    totalAccounts: number;
    recentSignups: Array<{
      date: ISODateString;
      email: string;
      engagement: string;
    }>;
  }
}
