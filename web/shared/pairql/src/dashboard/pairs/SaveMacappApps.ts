// auto-generated, do not edit
import type { BlockedMacApp, SuccessOutput, UnrestrictedMacApp } from '../shared';

export namespace SaveMacappApps {
  export interface Input {
    id: UUID;
    blockedApps: BlockedMacApp[];
    unrestrictedApps: UnrestrictedMacApp[];
  }

  export type Output = SuccessOutput;
}
