// auto-generated, do not edit
import type { PersonRelationship } from '../shared';

export namespace CreatePerson {
  export interface Input {
    name: string;
    relationship: PersonRelationship;
  }

  export interface Output {
    personId: UUID;
    name: string;
    relationship: PersonRelationship;
  }
}
