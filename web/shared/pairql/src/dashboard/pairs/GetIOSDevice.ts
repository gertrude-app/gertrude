// auto-generated, do not edit
import type { BlockRule, WebPolicy } from '../shared';

export namespace GetIOSDevice {
  export type Input = UUID;

  export interface Output {
    childName: string;
    deviceType: string;
    osVersion: string;
    allBlockGroups: Array<{
      id: UUID;
      name: string;
    }>;
    enabledBlockGroups: UUID[];
    webPolicy: WebPolicy;
    webPolicyDomains: string[];
    customBlockRules: Array<{
      id: UUID;
      rule: BlockRule;
    }>;
  }
}
