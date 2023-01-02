// auto-generated, do not edit
import type { SuccessOutput } from '../shared';
import type Result from '../../lib/Result';
import { pqlQuery } from '../query';
import { ClientAuth } from '../shared';

export namespace SaveKey {
  export interface Input {
    isNew: boolean;
    id: UUID;
    keychainId: UUID;
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
    comment?: string;
    expiration?: ISODateString;
  }

  export type Output = SuccessOutput;

  export async function fetch(input: Input): Promise<Result<Output, string>> {
    return pqlQuery<Input, Output>(input, ClientAuth.admin, `SaveKey`);
  }
}
