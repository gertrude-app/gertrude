// auto-generated, do not edit
export namespace GetParentRecentTelemetry {
  export interface Input {
    parentId: UUID;
    sinceHours: number;
    limit: number;
  }

  export type Output = Array<{
    id: UUID;
    createdAt: ISODateString;
    domain: string;
    operation: string;
    durationMs: number;
    result: string;
    errorId?: string;
    errorType?: string;
    errorMessage?: string;
    requestId: string;
    ipAddress?: string;
    userAgent?: string;
    numRequestBytes?: number;
    numResponseBytes?: number;
  }>;
}
