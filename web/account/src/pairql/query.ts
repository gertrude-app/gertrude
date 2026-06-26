import { useQuery as useReactQuery, useQueryClient } from '@tanstack/react-query';
import type { QueryKey } from './keys';
import type { PqlError, Result } from '@shared/pairql';
import type { UseQueryOptions, UseQueryResult } from '@tanstack/react-query';

type QueryOptions<T> = Omit<UseQueryOptions<T, PqlError>, `queryKey` | `queryFn`>;

export function useQuery<T>(
  key: QueryKey<T>,
  fn: () => Promise<Result<T, PqlError>>,
  options: QueryOptions<T> = {},
): UseQueryResult<T, PqlError> {
  return useReactQuery<T, PqlError>({
    queryKey: key.segments,
    queryFn: async () => (await fn()).valueOrThrow(),
    ...options,
  });
}

export function useOptimism(): { update<T>(key: QueryKey<T>, to: T): void } {
  const queryClient = useQueryClient();
  return {
    update<T>(key: QueryKey<T>, to: T) {
      // cancel in-flight refetches that would clobber the optimistic value
      queryClient.cancelQueries({ queryKey: key.segments });
      queryClient.setQueryData(key.segments, to);
    },
  };
}
