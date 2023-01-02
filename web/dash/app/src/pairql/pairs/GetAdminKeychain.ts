// auto-generated, do not edit
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace GetAdminKeychain {
  export type Input = UUID;

  export interface Output {
    id: UUID;
    name: string;
    description?: string;
    isPublic: boolean;
    authorId: UUID;
    keys: Array<{
      id: UUID;
      comment?: string;
      expiration?: ISODateString;
      key:
        | {
            type: 'Domain';
            value: {
              domain: string;
              scope: unknown /* !! runtime introspection failed */;
            };
          }
        | {
            type: 'AnySubdomain';
            value: {
              domain: string;
              scope: unknown /* !! runtime introspection failed */;
            };
          }
        | {
            type: 'Skeleton';
            value: {
              scope: unknown /* !! runtime introspection failed */;
            };
          }
        | {
            type: 'DomainRegex';
            value: {
              pattern: string;
              scope: unknown /* !! runtime introspection failed */;
            };
          }
        | {
            type: 'Path';
            value: {
              path: string;
              scope: unknown /* !! runtime introspection failed */;
            };
          }
        | {
            type: 'IpAddress';
            value: {
              ipAddress: string;
              scope: unknown /* !! runtime introspection failed */;
            };
          };
    }>;
  }

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `GetAdminKeychain`);
  }
}
