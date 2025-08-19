// auto-generated, do not edit
import type { BlockRule } from '../shared';

export namespace UpsertBlockRule {
  export interface Input {
    id?: UUID;
    deviceId: UUID;
    rule: BlockRule;
  }

  export type Output = UUID;
}
