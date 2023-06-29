import { useState } from 'react';
import toast from 'react-hot-toast';
import { useMutation as useLibMutation, useQueryClient } from '@tanstack/react-query';
import { capitalize, pastTense } from '@shared/string';
import type {
  ConfirmableEntityAction,
  DeleteEntity,
  PqlError,
  SuccessOutput,
  Result,
} from '@dash/types';
import type { UseMutationResult } from '@tanstack/react-query';
import type { QueryKey } from './key';
import Current from '../environment';
import { isEditable, isUUID } from '../lib/helpers';

export function useMutation<T, V>(
  fn: (arg: V) => Promise<Result<T>>,
  options: MutationOptions<T> = {},
): MutationResult<T, V> {
  const [entityId, setEntityId] = useState<UUID | undefined>(undefined);
  const queryClient = useQueryClient();
  const toasting = getToast(options.toast);
  return useLibMutation({
    mutationFn: (arg) => fn(arg).then((result) => result.valueOrThrow()),
    onMutate(arg) {
      if (isUUID(arg)) {
        setEntityId(arg);
      } else if (isEditable(arg)) {
        setEntityId(arg.original.id);
      }
      if (toasting) {
        toast.dismiss();
        const { verb, entity } = toasting;
        toast.loading(`${capitalize(verb).replace(/e$/, ``)}ing ${entity}...`);
      }
    },
    onError(error) {
      if (options.onError) {
        options.onError(error, entityId);
      }
      if (toasting) {
        toast.dismiss();
        const { verb, entity } = toasting;
        toast.error(`Failed to ${verb} ${entity}`, { duration: 6000 });
      }
    },
    onSuccess(payload) {
      if (options.onSuccess) {
        options.onSuccess(payload, entityId);
      }
      if (toasting) {
        toast.dismiss();
        const { verb, entity } = toasting;
        toast.success(`${capitalize(entity)} ${pastTense(verb)}!`);
      }
    },
    onSettled() {
      if (options.invalidating) {
        options.invalidating.forEach((key) =>
          queryClient.invalidateQueries(key.segments),
        );
      }
    },
  });
}

export function useDeleteEntity(
  type: DeleteEntity.Input['type'],
  options: MutationOptions<SuccessOutput> = {},
): MutationResult<SuccessOutput, UUID> {
  return useMutation((id: UUID) => Current.api.deleteEntity({ type, id }), {
    toast: toastIdFromDeleteEntityType(type),
    ...options,
  });
}

export function useConfirmableDelete(
  entityType: DeleteEntity.Input['type'],
  options: MutationOptions<SuccessOutput> & { id?: UUID } = {},
): ConfirmableEntityAction<UUID | void> & {
  state: 'idle' | 'loading' | 'error' | 'success';
} {
  const [stateId, setStateId] = useState<UUID | undefined>();
  const mutation = useDeleteEntity(entityType, options);

  return {
    id: stateId,
    start: (argId?: UUID) => setStateId(argId ?? options.id ?? ``),
    confirm: () => {
      mutation.mutate(stateId ?? ``);
      setStateId(undefined);
    },
    cancel: () => setStateId(undefined),
    state: mutation.status,
  };
}

type MutationOptions<T> = {
  toast?: ToastId;
  invalidating?: QueryKey<unknown>[];
  onSuccess?: (payload: T, entityId?: UUID) => unknown;
  onError?: (error: PqlError, entityId?: UUID) => unknown;
};

export type MutationResult<T, V> = UseMutationResult<T, PqlError, V>;

type ToastId =
  | 'delete:user'
  | 'delete:device'
  | 'delete:notification'
  | 'delete:notification-method'
  | 'delete:keychain'
  | 'delete:key'
  | 'delete:activity-items'
  | 'update:suspend-filter-request'
  | 'create:pending-notification-method'
  | 'confirm:pending-notification-method'
  | 'save:user'
  | 'save:keychain'
  | 'save:key'
  | 'save:notification';

function getToast(toastId?: ToastId): { verb: string; entity: string } | undefined {
  if (!toastId) {
    return undefined;
  }
  const [verb = ``, entitySlug = ``] = toastId.split(`:`);
  const entity = entitySlug.replace(/-/g, ` `);
  switch (toastId) {
    case `delete:user`:
    case `delete:device`:
    case `delete:notification`:
    case `delete:keychain`:
    case `delete:notification-method`:
    case `delete:key`:
    case `update:suspend-filter-request`:
    case `save:user`:
    case `save:keychain`:
    case `save:key`:
    case `save:notification`:
      return { verb, entity };

    case `create:pending-notification-method`:
      return { verb: `send`, entity: `verification code` };
    case `confirm:pending-notification-method`:
      return { verb: `verify`, entity: `confirmation code` };
    case `delete:activity-items`:
      return { verb: `approve`, entity: `activity items` };
  }
}

function toastIdFromDeleteEntityType(type: DeleteEntity.Input['type']): ToastId {
  switch (type) {
    case `adminNotification`:
      return `delete:notification`;
    case `adminVerifiedNotificationMethod`:
      return `delete:notification-method`;
    case `device`:
      return `delete:device`;
    case `key`:
      return `delete:key`;
    case `keychain`:
      return `delete:keychain`;
    case `user`:
      return `delete:user`;
  }
}
