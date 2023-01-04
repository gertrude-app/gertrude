// auto-generated, do not edit
import type { SuccessOutput } from '../shared';

export namespace DeleteActivityItems {
  export interface Input {
    userId: UUID;
    keystrokeLineIds: UUID[];
    screenshotIds: UUID[];
  }

  export type Output = SuccessOutput;
}
