import { Result } from '@dash/utils';

export default class PairQLResult<T, E = PqlError> extends Result<T, E> {}
