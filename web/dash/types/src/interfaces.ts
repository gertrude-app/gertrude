import type { JSXElementConstructor, ComponentProps } from 'react';
import type { RequestStatus } from './api';

type RemoveFns<T> = {
  [K in keyof T as T[K] extends (...args: any) => any ? never : K]: T[K];
};

export type Subcomponents<
  T extends keyof JSX.IntrinsicElements | JSXElementConstructor<any>,
> = Array<RemoveFns<ComponentProps<T>> & { id: string }>;

export interface ConfirmableEntityAction<StartArg = UUID> {
  id?: UUID;
  start(id: StartArg): unknown;
  confirm(): unknown;
  cancel(): unknown;
}

export interface DashboardWidgetData {
  unlockRequests: Array<{
    id: UUID;
    target: string;
    userId: UUID;
    userName: string;
    comment?: string | null;
    createdAt: string;
  }>;
  users: Array<{
    id: UUID;
    name: string;
    isOnline: boolean;
  }>;
  userActivity: Array<{
    id: UUID;
    userName: string;
    numUnreviewed: number;
  }>;
  userScreenshots: Array<{
    id: UUID;
    userName: string;
    url: string;
    createdAt: string;
  }>;
}

export interface UnlockRequest {
  id: UUID;
  userId: UUID;
  userName: string;
  status: RequestStatus;
  url?: string;
  domain?: string;
  ipAddress?: string;
  requestComment?: string;
  appName?: string;
  appSlug?: string;
  appBundleId?: string;
  appCategories: string[];
  requestProtocol?: string;
  createdAt: string;
}
