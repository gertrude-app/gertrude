// auto-generated, do not edit
export namespace MacAppConnectionCode {
  export interface Input {
    childId: UUID;
  }

  export interface Output {
    code: number;
    gate?: `trialRequired` | `planUpgradeRequired` | `subscriptionFixRequired`;
  }
}
