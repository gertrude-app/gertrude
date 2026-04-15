// auto-generated, do not edit
export namespace CreatePendingNotificationMethod {
  export type Input =
    | {
        case: 'slack';
        channelId: string;
        channelName: string;
        token: string;
      }
    | {
        case: 'email';
        email: string;
      }
    | {
        case: 'text';
        phoneNumber: string;
      }
    | {
        case: 'ntfy';
        topic: string;
      };

  export interface Output {
    methodId: UUID;
    ntfyTopic?: string;
  }
}
