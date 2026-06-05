export type NotificationMethod =
  | {
      type: `email`;
      emailAddress: string;
    }
  | {
      type: `sms`;
      phoneNumber: string;
    }
  | {
      type: `slack`;
      channelName: string;
      channelId: string;
      botToken: string;
    }
  | {
      type: `ntfy`;
      topicId: string;
    }
  | {
      type: `push`;
    };
