// auto-generated, do not edit
export namespace IOSDetailedStats {
  export type Input = void;

  export interface Output {
    dateRange: {
      start: ISODateString;
      end: ISODateString;
      totalDays: number;
    };
    overview: {
      firstLaunches: number;
      parentFalseStarts: number;
      adjustedLaunches: number;
      totalSuccess: number;
      successPct: number;
    };
    outcomes: {
      success: {
        count: number;
        pct: number;
      };
      parentDevice: {
        count: number;
        pct: number;
      };
      childOnboardingIssue: {
        count: number;
        pct: number;
      };
      stuckIn18Plus: {
        count: number;
        pct: number;
      };
      fullInstallFailed: {
        count: number;
        pct: number;
      };
      earlyDrop: {
        count: number;
        pct: number;
      };
    };
    successBreakdown: {
      screenTime: {
        count: number;
        pctOfSuccess: number;
        pctOfLaunch: number;
      };
      configurator: {
        count: number;
        pctOfSuccess: number;
        pctOfLaunch: number;
      };
      gertrudeSupervision: {
        count: number;
        pctOfSuccess: number;
        pctOfLaunch: number;
      };
      nonSupervisedConnection: {
        count: number;
        pctOfSuccess: number;
        pctOfLaunch: number;
      };
    };
    installFailures: {
      invalidAccountType: number;
      authCanceled: number;
      authRestricted: number;
      filterInstallFailed: number;
      total: number;
    };
    cacheClearing: {
      started: number;
      completed: number;
      errors: number;
      successRate: number;
      onboardingStarted: number;
      onboardingCompleted: number;
      infoStarted: number;
      infoCompleted: number;
    };
    devices: {
      iphone: {
        count: number;
        pct: number;
      };
      ipad: {
        count: number;
        pct: number;
      };
    };
    topRegions: Array<{
      region: string;
      name: string;
      count: number;
    }>;
    topIOSVersions: Array<{
      version: string;
      count: number;
    }>;
    funnelEvents: Array<{
      id: string;
      name: string;
      count: number;
    }>;
    dropoffEvents: Array<{
      id: string;
      name: string;
      count: number;
    }>;
    errorEvents: Array<{
      id: string;
      name: string;
      count: number;
    }>;
    supervision: {
      totalClaims: number;
      pendingClaim: number;
      claimed: number;
      supervised: number;
      complete: number;
    };
  }
}
