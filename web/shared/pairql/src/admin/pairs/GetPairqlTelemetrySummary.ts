// auto-generated, do not edit
export namespace GetPairqlTelemetrySummary {
  export interface Input {
    sinceHours: number;
  }

  export type Output = Array<{
    domain: string;
    operation: string;
    requestCount: number;
    p50Ms: number;
    p95Ms: number;
    p99Ms: number;
    maxMs: number;
    okCount: number;
    pqlErrorCount: number;
    convertibleErrorCount: number;
    unexpectedErrorCount: number;
    notFoundCount: number;
  }>;
}
