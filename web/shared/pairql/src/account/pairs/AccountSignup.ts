// auto-generated, do not edit
export namespace AccountSignup {
  export interface Input {
    email: string;
    password: string;
    gclid?: string;
    abTestVariant?: string;
    referralCode?: string;
    turnstileToken?: string;
  }

  export interface Output {
    account?: {
      accountId: UUID;
      token: UUID;
    };
  }
}
