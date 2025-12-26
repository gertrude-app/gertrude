import type { UnlockRequest } from './pairql';
import type { PqlError as SharedPqlError } from '@shared/pairql/src/PqlError';
import type React from 'react';
import type { ComponentProps, JSXElementConstructor } from 'react';

export type RemoveFns<T> = {
  [K in keyof T as T[K] extends (...args: any) => any ? never : K]: T[K];
};

export type Subcomponents<
  T extends keyof React.JSX.IntrinsicElements | JSXElementConstructor<any>,
> = Array<RemoveFns<ComponentProps<T>> & { id: string }>;

export interface ConfirmableEntityAction<StartArg = UUID> {
  id?: UUID;
  start(id: StartArg): unknown;
  confirm(): unknown;
  cancel(): unknown;
}

export type UnlockRequestCreateKeyData = Pick<
  UnlockRequest,
  `url` | `domain` | `ipAddress` | `appCategories` | `appBundleId` | `appSlug`
>;

export type PqlError = SharedPqlError;

export type RequestState<T = void, E = PqlError> =
  | { state: `idle` }
  | { state: `ongoing` }
  | { state: `failed`; error?: E }
  | { state: `succeeded`; payload: T };
