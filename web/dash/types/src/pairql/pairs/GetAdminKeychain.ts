// auto-generated, do not edit
import type { KeychainSummary, Key } from '../shared';

export namespace GetAdminKeychain {
  export type Input = UUID;

  export interface Output {
    summary: KeychainSummary;
    keys: Key[];
  }
}
