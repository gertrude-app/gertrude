// auto-generated, do not edit
import type { MusicSubscriptionState, PersonRelationship } from '../shared';

export namespace GetAccountIOSClaimData {
  export interface Input {
    flow: 'blockerConnect' | 'blockerSupervise' | 'podcasts' | 'music';
    code: number;
  }

  export interface Output {
    people: Array<{
      id: UUID;
      name: string;
      relationship: PersonRelationship;
    }>;
    modelName: string;
    modelIdentifier: string;
    deviceType: string;
    iosVersion: string;
    assignment?: {
      personId: UUID;
      personName: string;
      deviceId: UUID;
      amSubscription?:
        | {
            case: 'active';
            expiresAt: ISODateString;
          }
        | {
            case: 'fullTrial';
            expiresAt: ISODateString;
          }
        | {
            case: 'amTrial';
            expiresAt: ISODateString;
          }
        | {
            case: 'unpaid';
            remediationUrl?: string;
          }
        | {
            case: 'legacyGrandfathered';
            accessEndsAt: ISODateString;
            showMigrationNag: boolean;
            migrationUrl?: string;
          }
        | {
            case: 'legacyExpired';
            paidAt: ISODateString;
            remediationUrl?: string;
          }
        | {
            case: 'complimentary';
          };
      musicSubscription?: MusicSubscriptionState;
      supervisionStatus?: 'pendingClaim' | 'claimed' | 'supervised' | 'complete';
      requiresPayment: boolean;
    };
  }
}
