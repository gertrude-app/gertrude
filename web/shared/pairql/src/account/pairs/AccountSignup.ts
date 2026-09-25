// auto-generated, do not edit
export namespace AccountSignup {
  export interface Input {
    email: string;
    password: string;
    redirect?: string;
    turnstileToken?: string;
  }

  export interface Output {
    accountId?: UUID;
    token?: UUID;
  }
}
