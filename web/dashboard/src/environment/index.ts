import { ApiClient, liveApiClient, noopApiClient, throwingApiClient } from './ApiClient';
import {
  EnvironmentClient,
  LiveEnvironment,
  NoopEnvironment,
  ThrowingEnvironment,
} from './Environment';
import { StorageClient, LiveStorage, NoopStorage, ThrowingStorage } from './Storage';

export interface Environment {
  api: ApiClient;
  env: EnvironmentClient;
  localStorage: StorageClient;
  sessionStorage: StorageClient;
}

export const live: Environment = {
  api: liveApiClient,
  env: new LiveEnvironment(),
  localStorage: new LiveStorage(window.localStorage),
  sessionStorage: new LiveStorage(window.sessionStorage),
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

const Current = live;

export default Current;
