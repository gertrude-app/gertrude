// auto-generated, do not edit
export namespace StripeUrl_v2 {
  export interface Input {
    successPath: string;
    cancelPath: string;
    tier?: 'light' | 'full';
    associatedIosDeviceId?: UUID;
  }

  export interface Output {
    url: string;
  }
}
