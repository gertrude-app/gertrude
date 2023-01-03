// auto-generated, do not edit

export namespace CreatePendingNotificationMethod {
  export type Input =
    | {
        type: 'EmailInput';
        value: {
          email: string;
        };
      }
    | {
        type: 'TextInput';
        value: {
          phoneNumber: string;
        };
      }
    | {
        type: 'SlackInput';
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
