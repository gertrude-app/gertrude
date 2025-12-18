// auto-generated, do not edit
import type { DeviceModelFamily } from '../shared';

export namespace ParentDetail {
  export interface Input {
    id: UUID;
  }

  export interface Output {
    id: UUID;
    email: string;
    subscriptionStatus: string;
    subscriptionId?: string;
    monthlyPriceInCents: number;
    createdAt: ISODateString;
    children: Array<{
      id: UUID;
      name: string;
      keyloggingEnabled: boolean;
      screenshotsEnabled: boolean;
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
