// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace SaveKeychain {
  export interface Input {
    isNew: boolean;
    id: UUID;
    name: string;
    description?: string;
    isPublic: boolean;
  }

  export type Output = SuccessOutput;
}
