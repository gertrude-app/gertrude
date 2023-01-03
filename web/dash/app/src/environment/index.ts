import type { EnvironmentClient } from './Environment';
import type { StorageClient } from './Storage';
import type { ApiClient } from '../pairql/client';
import liveApiClient, { throwingClient as throwingApiClient } from '../pairql/client';
import noopApiClient from '../pairql/noopClient';
import { LiveEnvironment, NoopEnvironment, ThrowingEnvironment } from './Environment';
import { LiveStorage, NoopStorage, ThrowingStorage } from './Storage';

export interface Environment {
  api: ApiClient;
  env: EnvironmentClient;
  localStorage: StorageClient;
  sessionStorage: StorageClient;
}

export const live: Environment = {
  api: liveApiClient,
  env: new LiveEnvironment(),
  localStorage:
    typeof window !== `undefined`
      ? new LiveStorage(window.localStorage)
      : new ThrowingStorage(`local`),
  sessionStorage:
    typeof window !== `undefined`
      ? new LiveStorage(window.sessionStorage)
      : new ThrowingStorage(`session`),
};

export const throwing: Environment = {
  api: throwingApiClient,
  env: new ThrowingEnvironment(),
  localStorage: new ThrowingStorage(`local`),
  sessionStorage: new ThrowingStorage(`session`),
};

export const noop: Environment = {
  api: noopApiClient,
  env: new NoopEnvironment(),
  localStorage: new NoopStorage(),
  sessionStorage: new NoopStorage(),
};

const Current = import.meta.env.VITEST ? throwing : live;

export default Current;
