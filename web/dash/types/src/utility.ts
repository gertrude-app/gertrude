import type { JSXElementConstructor, ComponentProps } from 'react';
import type { UnlockRequest, ServerPqlError } from './pairql';

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

export type PqlError = Omit<
  ServerPqlError,
  | 'requestId'
  | 'version'
  | 'statusCode'
  | 'showContactSupport'
  | 'type'
  | 'dashboardTag'
  | 'appTag'
> & {
  isPqlError: true;
  type: ServerPqlError['type'] | 'clientError';
  tag?: ServerPqlError['dashboardTag'];
  showContactSupport?: boolean;
  serverRequestId?: string;
  clientRequestId?: string;
};

export type RequestState<T = void, E = PqlError> =
  | { state: 'idle' }
  | { state: 'ongoing' }
  | { state: 'failed'; error?: E }
  | { state: 'succeeded'; payload: T };
// TODO: can i make error non-optional?
