// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

export type BlockRule =
  | { case: 'bundleIdContains'; value: string }
  | { case: 'urlContains'; value: string }
  | { case: 'hostnameContains'; value: string }
  | { case: 'hostnameEquals'; value: string }
  | { case: 'hostnameEndsWith'; value: string }
  | { case: 'hostnameOrSubdomain'; value: string }
  | { case: 'targetContains'; value: string }
  | { case: 'flowTypeIs'; value: 'browser' | 'socket' }
  | { case: 'both'; a: BlockRule; b: BlockRule }
  | { case: 'unless'; rule: BlockRule; negatedBy: BlockRule[] };

export type ClientAuth = 'none' | 'child' | 'parent' | 'superAdmin';

export type PersonRelationship = 'child' | 'peer' | 'self';

export interface SuccessOutput {
  success: boolean;
}
