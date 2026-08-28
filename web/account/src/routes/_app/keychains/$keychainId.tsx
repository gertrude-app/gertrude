import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { KeychainDetail, LoadableState } from '#/components/types';
import KeychainDetailPage from '#/components/pages/keychains/KeychainDetailPage';
import { apiEndpoint, liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const KeychainDetailRoute: React.FC = () => {
  const { keychainId } = Route.useParams();
  const queryKey = Key.keychain(keychainId);
  const query = useQuery(queryKey, () => liveClient.getAccountKeychain({ keychainId }));
  const saveKey = useMutation(liveClient.saveAccountKey, {
    invalidating: [queryKey, Key.keychains],
    toast: {
      loading: `Saving key…`,
      success: `Key saved`,
      error: `Couldn't save this key.`,
    },
  });
  const deleteKey = useMutation(liveClient.deleteAccountKey, {
    invalidating: [queryKey, Key.keychains],
    toast: {
      loading: `Deleting key…`,
      success: `Key deleted`,
      error: `Couldn't delete this key.`,
    },
  });
  const state: LoadableState<KeychainDetail> =
    query.data !== undefined
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
      : query.isError
        ? {
            status: `error`,
            message:
              query.error.userMessage ??
              (query.error.type === `notFound`
                ? `This keychain may have been deleted or belong to another account.`
                : `Check your connection and try again.`),
            onRetry: () => void query.refetch(),
          }
        : { status: `loading` };

  return (
    <KeychainDetailPage
      state={state}
      savingKey={saveKey.isPending}
      deletingKey={deleteKey.isPending}
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
