// auto-generated, do not edit
import type { PersonRelationship } from '../shared';

export namespace GetAccountBlockerClaimData {
  export interface Input {
    code: number;
  }

  export interface Output {
    people: Array<{
      id: UUID;
      name: string;
      relationship: PersonRelationship;
    }>;
    modelName: string;
    modelIdentifier: string;
    deviceType: string;
    iosVersion: string;
    assignment?: {
      personId: UUID;
      personName: string;
      deviceId: UUID;
    };
  }
}
