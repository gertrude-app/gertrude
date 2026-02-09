// auto-generated, do not edit
export namespace CreatePendingAppConnection_v2 {
  export interface Input {
    childId: UUID;
  }

  export interface Output {
    code: number;
    gate?: `trialRequired` | `planUpgradeRequired` | `subscriptionFixRequired`;
  }
}
