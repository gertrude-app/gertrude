// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetSelectableKeychains {
  export type Input = void;

  export interface Keychain {
    id: UUID;
    name: string;
    isPublic: boolean;
    authorId: UUID;
    description?: string;
    numKeys: number;
  }

  export interface Output {
    own: Array<Keychain>;
    public: Array<Keychain>;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetSelectableKeychains`);
  }
}
