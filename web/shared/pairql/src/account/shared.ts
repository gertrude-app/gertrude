// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

export type AppScope =
  | { type: 'unrestricted' }
  | { type: 'webBrowsers' }
  | { type: 'single'; single: SingleAppScope };

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

export type SharedKey =
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'skeleton'; scope: SingleAppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope };

export type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

export interface SuccessOutput {
  success: boolean;
}
