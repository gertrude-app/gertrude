import { Result } from '@dash/utils';

export type PqlError = {
  debugMessage: string;
  userFacingMessage?: string;
  errorId?: UUID;
  clientRequestId?: UUID;
  serverRequestId?: UUID;
};

export default class PairQLResult<T, E = PqlError> extends Result<T, E> {}
