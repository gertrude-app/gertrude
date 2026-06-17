// auto-generated, do not edit
import type {
  DeviceModelFamily,
  PlanStatus,
  StripeSubscriptionStatus,
  SubscriptionTier,
} from '../shared';

export namespace ParentDetail {
  export interface Input {
    id: UUID;
  }

  export interface Output {
    id: UUID;
    email: string;
    status: string;
    planStatus: PlanStatus;
    subscription?: {
      tier: SubscriptionTier;
      stripeStatus: StripeSubscriptionStatus;
      stripeId: string;
      currentPeriodEnd: ISODateString;
      isLegacyPrice: boolean;
    };
    createdAt: ISODateString;
    children: Array<{
      id: UUID;
      name: string;
      keyloggingEnabled: boolean;
      screenshotsEnabled: boolean;
      filteringDisabled: boolean;
      createdAt: ISODateString;
      installations: Array<{
        id: UUID;
        appVersion: string;
        filterVersion?: string;
        osVersion?: string;
        modelIdentifier: string;
        modelFamily: DeviceModelFamily;
        modelTitle: string;
        createdAt: ISODateString;
      }>;
      iosDevices: Array<{
        id: UUID;
        modelName: string;
        modelIdentifier: string;
        iosVersion: string;
        appVersion: string;
        supervisionStatus?: string;
        lastCheckin?: ISODateString;
        createdAt: ISODateString;
      }>;
      keychains: Array<{
        id: UUID;
        name: string;
        numKeys: number;
        isPublic: boolean;
      }>;
    }>;
    keychains: Array<{
      id: UUID;
      name: string;
      numKeys: number;
      isPublic: boolean;
    }>;
    notifications: Array<{
      id: UUID;
      trigger: string;
    }>;
  }
}
