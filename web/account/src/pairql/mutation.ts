import { toast } from '@gertrude/ui';
import { useMutation as useReactMutation, useQueryClient } from '@tanstack/react-query';
import type { QueryKey } from './keys';
import type { PqlError, Result } from '@shared/pairql';
import type { UseMutationResult } from '@tanstack/react-query';

type ToastMessages = {
  loading: string;
  success: string;
  error: string;
};

type MutationOptions<T> = {
  toast?: ToastMessages;
  invalidating?: QueryKey<unknown>[];
  onSuccess?: (payload: T) => unknown;
  onError?: (error: PqlError) => unknown;
};

export function useMutation<T, V>(
  fn: (arg: V) => Promise<Result<T, PqlError>>,
  options: MutationOptions<T> = {},
): UseMutationResult<T, PqlError, V> {
  const queryClient = useQueryClient();
  return useReactMutation<T, PqlError, V>({
    mutationFn: (arg) => {
      const promise = fn(arg).then((result) => result.valueOrThrow());
      const messages = options.toast;
      if (messages) {
        toast.async(promise, {
          loading: messages.loading,
          success: messages.success,
          error: (error) =>
            (error as PqlError | undefined)?.userMessage ?? messages.error,
        });
      }
      return promise;
    },
    onSuccess: options.onSuccess,
    onError: options.onError,
    onSettled() {
      options.invalidating?.forEach((key) =>
        queryClient.invalidateQueries({ queryKey: key.segments }),
      );
    },
  });
}
