// auto-generated, do not edit
import type { KeychainSummary } from '../shared';

export namespace GetSelectableKeychains {
  export type Input = void;

  export interface Output {
    own: Array<KeychainSummary>;
    public: Array<KeychainSummary>;
  }
}
