import type { EnvironmentClient } from './Environment';
import type { StorageClient } from './Storage';
import type { ApiClient } from '../pairql/client';
import { liveClient as liveApiClient } from '../pairql/client';
import { LiveEnvironment } from './Environment';
import { LiveStorage, ThrowingStorage } from './Storage';

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

export default live;
