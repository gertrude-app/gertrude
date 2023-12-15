import type { RequestState } from '@dash/types';
import type { QueryResult } from '../hooks/query';
import type { MutationResult } from '../hooks/mutation';
import { ensurePqlError } from '../pairql/query';

export default class ReqState {
  static fromQuery<T>(query: QueryResult<T>): RequestState<T> {
    // disabled queries (waiting for enabled: true) are in this first state
    if (query.isPending && !query.isFetching) {
      return { state: `idle` };
    } else if (query.isPending) {
      return { state: `ongoing` };
    } else if (query.isError) {
      return { state: `failed`, error: ensurePqlError(query.error) };
    } else {
      return { state: `succeeded`, payload: query.data };
    }
  }

  static fromMutation<T, V>(mutation: MutationResult<T, V>): RequestState<T> {
    switch (mutation.status) {
      case `idle`:
        return { state: `idle` };
      case `pending`:
        return { state: `ongoing` };
      case `error`:
        return { state: `failed`, error: ensurePqlError(mutation.error) };
      case `success`:
        return { state: `succeeded`, payload: mutation.data };
    }
  }
}
