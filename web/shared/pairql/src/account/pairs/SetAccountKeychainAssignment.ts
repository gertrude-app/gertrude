// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace SetAccountKeychainAssignment {
  export interface Input {
    keychainId: UUID;
    personId: UUID;
    assigned: boolean;
  }

  export type Output = SuccessOutput;
}
