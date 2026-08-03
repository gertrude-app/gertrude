// auto-generated, do not edit
import type { PersonRelationship, SuccessOutput } from '../shared';

export namespace UpdatePersonBasicDetails {
  export interface Input {
    personId: UUID;
    name: string;
    relationship: PersonRelationship;
  }

  export type Output = SuccessOutput;
}
