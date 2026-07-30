import { toast } from '@gertrude/ui';
import { useMutation as useReactMutation, useQueryClient } from '@tanstack/react-query';
import type { QueryKey } from './keys';
import type { PqlError, Result } from '@shared/pairql';
import type { UseMutationResult } from '@tanstack/react-query';

type ToastMessage<Variables> = string | ((variables: Variables) => string);

type ToastMessages<Variables> = {
  loading: ToastMessage<Variables>;
  success: ToastMessage<Variables>;
  error: ToastMessage<Variables>;
};

type MutationOptions<T, Variables> = {
  toast?: ToastMessages<Variables>;
  invalidating?: QueryKey<unknown>[];
  onSuccess?: (payload: T) => unknown;
  onError?: (error: PqlError) => unknown;
};

export function useMutation<T, V>(
  fn: (arg: V) => Promise<Result<T, PqlError>>,
  options: MutationOptions<T, V> = {},
): UseMutationResult<T, PqlError, V> {
  const queryClient = useQueryClient();
  return useReactMutation<T, PqlError, V>({
    mutationFn: (arg) => {
      const promise = fn(arg).then((result) => result.valueOrThrow());
      const messages = options.toast;
      if (messages) {
        const message = (value: ToastMessage<V>): string =>
          typeof value === `function` ? value(arg) : value;

        void toast
          .async(promise, {
            loading: message(messages.loading),
            success: message(messages.success),
            error: (error) =>
              (error as PqlError | undefined)?.userMessage ?? message(messages.error),
          })
          .catch(() => undefined);
      }
      return promise;
    },
    onSuccess: options.onSuccess,
    onError: options.onError,
    onSettled() {
      return Promise.all(
        options.invalidating?.map((key) =>
          queryClient.invalidateQueries({ queryKey: key.segments }),
        ) ?? [],
      );
    },
  });
}
