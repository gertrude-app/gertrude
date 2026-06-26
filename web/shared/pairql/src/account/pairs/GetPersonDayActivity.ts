// auto-generated, do not edit
export namespace GetPersonDayActivity {
  export interface Input {
    personId: UUID;
    range: {
      start: string;
      end: string;
    };
  }

  export interface Output {
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
  }
}
