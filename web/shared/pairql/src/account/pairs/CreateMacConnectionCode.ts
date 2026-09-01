// auto-generated, do not edit
export namespace CreateMacConnectionCode {
  export interface Input {
    personId: UUID;
  }

  export interface Output {
    code: number;
    gate?: 'trialRequired' | 'planUpgradeRequired' | 'subscriptionFixRequired';
  }
}
