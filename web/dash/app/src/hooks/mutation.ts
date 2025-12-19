import { capitalize, pastTense } from '@shared/string';
import { useMutation as useLibMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import toast from 'react-hot-toast';
import type { QueryKey } from './key';
import type {
  ConfirmableEntityAction,
  DeleteEntity_v2,
  PqlError,
  SuccessOutput,
} from '@dash/types';
import type { Result } from '@shared/pairql';
import type { UseMutationResult } from '@tanstack/react-query';
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
          queryClient.invalidateQueries({ queryKey: key.segments }),
        );
      }
    },
  });
}

export function useDeleteEntity(
  type: DeleteEntity_v2.Input[`type`],
  options: MutationOptions<SuccessOutput> = {},
): MutationResult<SuccessOutput, UUID> {
  return useMutation((id: UUID) => Current.api.deleteEntity({ type, id }), {
    toast: toastIdFromDeleteEntityType(type),
    ...options,
  });
}

export function useConfirmableDelete(
  entityType: DeleteEntity_v2.Input[`type`],
  options: MutationOptions<SuccessOutput> & { id?: UUID } = {},
): ConfirmableEntityAction<UUID | void> & {
  state: `idle` | `pending` | `error` | `success`;
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
  | `delete:admin`
  | `delete:user`
  | `delete:computer`
  | `delete:block-rule`
  | `delete:notification`
  | `delete:notification-method`
  | `delete:keychain`
  | `delete:key`
  | `delete:activity-items`
  | `flag:activity-item`
  | `update:suspend-filter-request`
  | `create:pending-notification-method`
  | `confirm:pending-notification-method`
  | `save:user`
  | `save:keychain`
  | `save:key`
  | `save:computer`
  | `save:block-rule`
  | `save:ios-device`
  | `save:notification`;

function getToast(toastId?: ToastId): { verb: string; entity: string } | undefined {
  if (!toastId) return undefined;
  const [verb = ``, entitySlug = ``] = toastId.split(`:`);
  const entity = entitySlug.replace(/-/g, ` `);
  switch (toastId) {
    case `delete:computer`:
    case `delete:notification`:
    case `delete:keychain`:
    case `delete:notification-method`:
    case `delete:key`:
    case `delete:block-rule`:
    case `update:suspend-filter-request`:
    case `save:keychain`:
    case `save:key`:
    case `save:computer`:
    case `save:block-rule`:
    case `save:notification`:
      return { verb, entity };

    case `save:ios-device`:
      return { verb: `update`, entity: `iOS device` };

    case `flag:activity-item`:
      return { verb: `update`, entity: `item` };

    case `delete:user`:
    case `save:user`:
      return { verb, entity: `child` };

    case `delete:admin`:
      return { verb, entity: `account` };

    case `create:pending-notification-method`:
      return { verb: `send`, entity: `verification code` };
    case `confirm:pending-notification-method`:
      return { verb: `verify`, entity: `confirmation code` };
    case `delete:activity-items`:
      return { verb: `delete`, entity: `activity` };
  }
}

function toastIdFromDeleteEntityType(
  type: DeleteEntity_v2.Input[`type`],
): ToastId | undefined {
  switch (type) {
    case `parent`:
      return undefined;
    case `parentNotification`:
      return `delete:notification`;
    case `parentVerifiedNotificationMethod`:
      return `delete:notification-method`;
    case `computerUser`:
      return `delete:computer`;
    case `key`:
      return `delete:key`;
    case `keychain`:
      return `delete:keychain`;
    case `child`:
      return `delete:user`;
    case `blockRule`:
      return `delete:block-rule`;
    case `announcement`:
      return undefined;
  }
}
