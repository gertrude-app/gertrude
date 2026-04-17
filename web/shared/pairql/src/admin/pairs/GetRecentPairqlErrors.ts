// auto-generated, do not edit
export namespace GetRecentPairqlErrors {
  export interface Input {
    sinceHours: number;
    limit: number;
    resultFilter?: string;
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
  }>;
}
