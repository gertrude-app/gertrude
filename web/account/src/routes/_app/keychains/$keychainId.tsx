import { useQueryClient } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { KeychainDetail, LoadableState } from '#/components/types';
import useKeychainAssignments from '#/components/keychains/useKeychainAssignments';
import KeychainDetailPage from '#/components/pages/keychains/KeychainDetailPage';
import { apiEndpoint, liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const KeychainDetailRoute: React.FC = () => {
  const { keychainId } = Route.useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const queryKey = Key.keychain(keychainId);
  const invalidating = [
    Key.keychains,
    Key.people,
    Key.unlockRequests,
    Key.securityEvents,
  ];
  const query = useQuery(queryKey, () => liveClient.getAccountKeychain({ keychainId }));
  const keychains = useQuery(Key.keychains, () => liveClient.getAccountKeychains());
  const handleAssignmentChange = useKeychainAssignments(keychains.data?.people ?? []);
  const saveKeychain = useMutation(liveClient.saveAccountKeychain, {
    invalidating,
    toast: {
      loading: `Saving keychain…`,
      success: `Keychain updated`,
      error: `Couldn't save this keychain.`,
    },
  });
  const deleteKeychain = useMutation(liveClient.deleteAccountKeychain, {
    invalidating,
    toast: {
      loading: `Deleting keychain…`,
      success: `Keychain deleted`,
      error: `Couldn't delete this keychain.`,
    },
    onSuccess: () => {
      queryClient.removeQueries({ queryKey: queryKey.segments });
      return navigate({ to: `/keychains`, replace: true });
    },
  });
  const saveKey = useMutation(liveClient.saveAccountKey, {
    invalidating,
    toast: {
      loading: `Saving key…`,
      success: `Key saved`,
      error: `Couldn't save this key.`,
    },
  });
  const deleteKey = useMutation(liveClient.deleteAccountKey, {
    invalidating,
    toast: {
      loading: `Deleting key…`,
      success: `Key deleted`,
      error: `Couldn't delete this key.`,
    },
  });
  const state: LoadableState<KeychainDetail> =
    query.data !== undefined && keychains.data !== undefined
      ? {
          status: `success`,
          data: {
            ...query.data,
            apps: query.data.apps.map((app) => ({
              name: app.name,
              slug: app.slug,
              bundleId: app.bundleId,
              appIconUrl: app.iconHash
                ? `${apiEndpoint}/app-icon/${app.iconHash}`
                : undefined,
            })),
          },
        }
      : query.isError || keychains.isError
        ? {
            status: `error`,
            message:
              (query.error ?? keychains.error)?.userMessage ??
              (query.error?.type === `notFound`
                ? `This keychain may have been deleted or belong to another account.`
                : `Check your connection and try again.`),
            onRetry: () => void Promise.all([query.refetch(), keychains.refetch()]),
          }
        : { status: `loading` };

  return (
    <KeychainDetailPage
      state={state}
      people={keychains.data?.people ?? []}
      onAssignmentChange={(personId, assigned) =>
        handleAssignmentChange(keychainId, personId, assigned)
      }
      savingKey={saveKey.isPending}
      deletingKey={deleteKey.isPending}
      savingKeychain={saveKeychain.isPending}
      deletingKeychain={deleteKeychain.isPending}
      onSaveKeychain={(data) =>
        saveKeychain.mutateAsync({ keychainId, ...data }).then(() => undefined)
      }
      onDeleteKeychain={() =>
        deleteKeychain.mutateAsync({ keychainId }).then(() => undefined)
      }
      onSaveKey={(keyId, data) =>
        saveKey
          .mutateAsync({
            keychainId,
            keyId,
            key: data.key,
            comment: data.comment,
            expiration: data.expiration?.toISOString(),
          })
          .then(() => undefined)
      }
      onDeleteKey={(keyId) =>
        deleteKey.mutateAsync({ keychainId, keyId }).then(() => undefined)
      }
    />
  );
};

export const Route = createFileRoute(`/_app/keychains/$keychainId`)({
  component: KeychainDetailRoute,
});
