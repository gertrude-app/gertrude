import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { KeychainsPageData, LoadableState } from '#/components/types';
import useKeychainAssignments from '#/components/keychains/useKeychainAssignments';
import KeychainsPage from '#/components/pages/keychains/KeychainsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const KeychainsRoute: React.FC = () => {
  const navigate = useNavigate();
  const queryKey = Key.keychains;
  const query = useQuery(queryKey, () => liveClient.getAccountKeychains());
  const handleAssignmentChange = useKeychainAssignments(query.data?.people ?? []);
  const createKeychain = useMutation(liveClient.saveAccountKeychain, {
    invalidating: [queryKey, Key.people, Key.securityEvents],
    toast: {
      loading: `Creating keychain…`,
      success: `Keychain created`,
      error: `Couldn't create this keychain.`,
    },
  });
  const state: LoadableState<KeychainsPageData> =
    query.data !== undefined
      ? { status: `success`, data: query.data }
      : query.isError
        ? {
            status: `error`,
            message: query.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void query.refetch(),
          }
        : { status: `loading` };

  return (
    <KeychainsPage
      state={state}
      creatingKeychain={createKeychain.isPending}
      onCreateKeychain={async (data) => {
        const { id } = await createKeychain.mutateAsync(data);
        await navigate({ to: `/keychains/$keychainId`, params: { keychainId: id } });
      }}
      onAssignmentChange={handleAssignmentChange}
    />
  );
};

export const Route = createFileRoute(`/_app/keychains/`)({
  component: KeychainsRoute,
});
