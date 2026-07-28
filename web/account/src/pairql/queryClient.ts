import { isPqlError } from '@shared/pairql';
import { MutationCache, QueryCache, QueryClient } from '@tanstack/react-query';

const isLoggedOutError = (error: unknown): boolean =>
  isPqlError(error) && error.type === `loggedOut`;

export function createAccountQueryClient(onLoggedOut: () => void): QueryClient {
  const handleError = (error: unknown): void => {
    if (isLoggedOutError(error)) onLoggedOut();
  };

  return new QueryClient({
    queryCache: new QueryCache({ onError: handleError }),
    mutationCache: new MutationCache({ onError: handleError }),
    defaultOptions: {
      queries: {
        retry: (failureCount, error) => !isLoggedOutError(error) && failureCount < 3,
        refetchOnWindowFocus: false,
      },
    },
  });
}
