import {
  EnvironmentClient,
  LiveEnvironment,
  NoopEnvironment,
  ThrowingEnvironment,
} from './Environment';
import { StorageClient, LiveStorage, NoopStorage, ThrowingStorage } from './Storage';

export interface Environment {
  localStorage: StorageClient;
  sessionStorage: StorageClient;
  env: EnvironmentClient;
}

export const live: Environment = {
  localStorage: new LiveStorage(window.localStorage),
  sessionStorage: new LiveStorage(window.sessionStorage),
  env: new LiveEnvironment(),
};

export const throwing: Environment = {
  localStorage: new ThrowingStorage(`local`),
  sessionStorage: new ThrowingStorage(`session`),
  env: new ThrowingEnvironment(),
};

export const noop: Environment = {
  localStorage: new NoopStorage(),
  sessionStorage: new NoopStorage(),
  env: new NoopEnvironment(),
};

const Current = live;

export default Current;
