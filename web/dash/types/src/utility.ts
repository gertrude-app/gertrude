import type { JSXElementConstructor, ComponentProps } from 'react';
import type { UnlockRequest } from './pairql';

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

export type UnlockRequestCreateKeyData = Pick<
  UnlockRequest,
  'url' | 'domain' | 'ipAddress' | 'appCategories' | 'appBundleId' | 'appSlug'
>;
