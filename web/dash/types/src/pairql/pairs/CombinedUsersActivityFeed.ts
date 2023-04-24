// auto-generated, do not edit

export namespace CombinedUsersActivityFeed {
  export interface Input {
    range: {
      start: string;
      end: string;
    };
  }

  export type Item =
    | {
        type: 'Screenshot';
        value: {
          id: UUID;
          ids: UUID[];
          url: string;
          width: number;
          height: number;
          createdAt: ISODateString;
          deletedAt?: ISODateString;
        };
      }
    | {
        type: 'CoalescedKeystrokeLine';
        value: {
          id: UUID;
          ids: UUID[];
          appName: string;
          line: string;
          createdAt: ISODateString;
          deletedAt?: ISODateString;
        };
      };

  export type Output = Array<{
    userId: UUID;
    userName: string;
    numDeleted: number;
    items: Array<Item>;
  }>;
}
