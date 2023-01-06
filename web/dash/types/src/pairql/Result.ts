import { Result } from '@dash/utils';
import type { PqlError } from '../utility';

export default class PairQLResult<T, E = PqlError> extends Result<T, E> {
  public static unexpectedError(
    id: string,
    debugMessage: string,
  ): PairQLResult<never, PqlError> {
    return Result.error({
      id,
      type: `clientError`,
      debugMessage,
    });
  }
}
