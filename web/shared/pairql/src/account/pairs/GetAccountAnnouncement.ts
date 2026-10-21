// auto-generated, do not edit
export namespace GetAccountAnnouncement {
  export type Input = void;

  export interface Output {
    announcement?: {
      id: UUID;
      kind: 'news' | 'warning';
      html: string;
      action?: {
        label: string;
        url: string;
      };
    };
  }
}
