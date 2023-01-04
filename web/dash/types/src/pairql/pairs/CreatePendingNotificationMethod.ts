// auto-generated, do not edit

export namespace CreatePendingNotificationMethod {
  export type Input =
    | {
        type: 'Email';
        value: {
          email: string;
        };
      }
    | {
        type: 'Text';
        value: {
          phoneNumber: string;
        };
      }
    | {
        type: 'Slack';
        value: {
          token: string;
          channelId: string;
          channelName: string;
        };
      };

  export interface Output {
    methodId: UUID;
  }
}
