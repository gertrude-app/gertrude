import { describe, expect, test, vi } from 'vitest';
import type { PqlError } from '@shared/pairql';
import { createAccountQueryClient } from '../queryClient';

const loggedOutError: PqlError = {
  isPqlError: true,
  id: `ac701d5e`,
  type: `loggedOut`,
  debugMessage: `Account token not found`,
};

describe(`Account query client`, () => {
  test(`logs out without retrying a logged-out query`, async () => {
    const onLoggedOut = vi.fn();
    const queryClient = createAccountQueryClient(onLoggedOut);
    const query = vi.fn(async () => Promise.reject(loggedOutError));

    await expect(
      queryClient.fetchQuery({
        queryKey: [`logged-out-query`],
        queryFn: query,
        retryDelay: 0,
      }),
    ).rejects.toBe(loggedOutError);

    expect(query).toHaveBeenCalledTimes(1);
    expect(onLoggedOut).toHaveBeenCalledTimes(1);
  });

  test(`logs out after a logged-out mutation`, async () => {
    const onLoggedOut = vi.fn();
    const queryClient = createAccountQueryClient(onLoggedOut);
    const mutation = queryClient.getMutationCache().build(queryClient, {
      mutationFn: async () => Promise.reject(loggedOutError),
    });

    await expect(mutation.execute(undefined)).rejects.toBe(loggedOutError);

    expect(onLoggedOut).toHaveBeenCalledTimes(1);
  });

  test(`retains retries for non-authentication failures`, async () => {
    const onLoggedOut = vi.fn();
    const queryClient = createAccountQueryClient(onLoggedOut);
    const error = new Error(`Network error`);
    const query = vi.fn(async () => Promise.reject(error));

    await expect(
      queryClient.fetchQuery({
        queryKey: [`failed-query`],
        queryFn: query,
        retryDelay: 0,
      }),
    ).rejects.toBe(error);

    expect(query).toHaveBeenCalledTimes(4);
    expect(onLoggedOut).not.toHaveBeenCalled();
  });
});
