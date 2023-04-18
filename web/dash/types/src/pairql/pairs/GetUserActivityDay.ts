// auto-generated, do not edit

export namespace GetUserActivityDay {
  export interface Input {
    userId: UUID;
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

  export interface Output {
    userName: string;
    numDeleted: number;
    items: Item[];
  }
}
