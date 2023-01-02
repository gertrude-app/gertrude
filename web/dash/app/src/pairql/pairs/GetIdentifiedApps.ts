// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetIdentifiedApps {
  export type Input = void;

  export type Output = Array<{
    id: UUID;
    name: string;
    slug: string;
    selectable: boolean;
    bundleIds: Array<{
      id: UUID;
      bundleId: string;
    }>;
    category?: {
      id: UUID;
      name: string;
      slug: string;
    };
  }>;

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetIdentifiedApps`);
  }
}
