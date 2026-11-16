// auto-generated, do not edit
import type { ChildComputerStatus, PersonRelationship } from '../shared';

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
          computerId: UUID;
          username: string;
          name?: string;
          macOSVersion?: string;
          modelName: string;
          modelIdentifier: string;
          status: ChildComputerStatus;
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
