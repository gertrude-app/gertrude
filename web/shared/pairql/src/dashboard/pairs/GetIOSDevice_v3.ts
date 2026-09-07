// auto-generated, do not edit
import type {
  AmSubscriptionState,
  BlockRule,
  ExtendedSupervisionControls,
  MusicSubscriptionState,
  WebPolicy,
} from '../shared';

export namespace GetIOSDevice_v3 {
  export type Input = UUID;

  export interface Output {
    childName: string;
    deviceType: string;
    osVersion: string;
    blocker?: {
      allBlockGroups: Array<{
        id: UUID;
        name: string;
        description: string;
        longDescription: string;
      }>;
      enabledBlockGroups: UUID[];
      webPolicy: WebPolicy;
      webPolicyDomains: string[];
      customBlockRules: Array<{
        id: UUID;
        rule: BlockRule;
      }>;
      isSupervised: boolean;
      isProfileLocked: boolean;
      allowAppRemoval: boolean;
      allowEraseContentAndSettings: boolean;
      allowAppInstallation: boolean;
      extendedSupervisionControls?: ExtendedSupervisionControls;
    };
    am?: {
      subscription: AmSubscriptionState;
    };
    music?: {
      subscription: MusicSubscriptionState;
    };
    musicConnected: boolean;
  }
}
