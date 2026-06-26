// auto-generated, do not edit
export namespace GetDayActivity {
  export interface Input {
    range: {
      start: string;
      end: string;
    };
  }

  export interface Output {
    people: Array<{
      personId: UUID;
      personName: string;
      items: Array<
        | {
            case: 'screenshot';
            id: UUID;
            ids: UUID[];
            url: string;
            width: number;
            height: number;
            date: ISODateString;
            flagged: boolean;
            duringSuspension: boolean;
          }
        | {
            case: 'keylog';
            id: UUID;
            ids: UUID[];
            text: string;
            appName: string;
            date: ISODateString;
            flagged: boolean;
            duringSuspension: boolean;
          }
      >;
    }>;
  }
}
