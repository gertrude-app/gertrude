// auto-generated, do not edit
import type { AdminKeychain } from '../shared';

export namespace GetAdminKeychains {
  export type Input = void;

  export interface Output {
    keychains: AdminKeychain[];
    children: Array<{
      id: UUID;
      name: string;
    }>;
  }
}
