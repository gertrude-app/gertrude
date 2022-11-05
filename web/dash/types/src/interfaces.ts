import type { JSXElementConstructor, ComponentProps } from 'react';
import { RequestStatus } from './api';

export type Subcomponents<
  T extends keyof JSX.IntrinsicElements | JSXElementConstructor<any>,
> = Array<ComponentProps<T> & { id: string }>;

export type SubcomponentsOmit<
  T extends keyof JSX.IntrinsicElements | JSXElementConstructor<any>,
  K extends keyof ComponentProps<T>,
> = Array<Omit<ComponentProps<T> & { id: string }, K>>;

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

// https://github.com/snowpackjs/snowpack/discussions/1589
export const _SNOWPACK_INTERFACES = true;
