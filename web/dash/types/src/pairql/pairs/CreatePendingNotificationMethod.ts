// auto-generated, do not edit

export namespace CreatePendingNotificationMethod {
  export type Input =
    | {
        case: `slack`;
        channelId: string;
        channelName: string;
        token: string;
      }
    | {
        case: `email`;
        email: string;
      }
    | {
        case: `text`;
        phoneNumber: string;
      };

  export interface Output {
    methodId: UUID;
  }
}
