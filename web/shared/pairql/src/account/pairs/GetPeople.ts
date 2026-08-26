// auto-generated, do not edit
import type { PersonRelationship } from '../shared';

export namespace GetPeople {
  export type Input = void;

  export type Output = Array<{
    id: UUID;
    name: string;
    relationship: PersonRelationship;
    devices: Array<
      | {
          case: 'mac';
          id: UUID;
          name?: string;
          macOSVersion?: string;
          modelName: string;
          modelIdentifier: string;
          online: boolean;
        }
      | {
          case: 'ios';
          id: UUID;
          type: 'iphone' | 'ipad';
          iOSVersion: string;
          modelName: string;
          modelIdentifier: string;
          blockerConnected: boolean;
        }
    >;
    screenshot?: {
      url: string;
      createdAt: ISODateString;
    };
  }>;
}
