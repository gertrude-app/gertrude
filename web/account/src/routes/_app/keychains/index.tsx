import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { KeychainsPageData, LoadableState } from '#/components/types';
import type { GetAccountKeychains } from '@shared/pairql/src/account';
import KeychainsPage from '#/components/pages/keychains/KeychainsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism, useQuery } from '#/pairql/query';

const withAssignment = (
  data: GetAccountKeychains.Output,
  keychainId: string,
  personId: string,
  assigned: boolean,
): GetAccountKeychains.Output => ({
  ...data,
  keychains: data.keychains.map((keychain) => {
    if (keychain.id !== keychainId) {
      return keychain;
    }

    const assignedPersonIds = new Set(keychain.assignedPersonIds);
    if (assigned) {
      assignedPersonIds.add(personId);
    } else {
      assignedPersonIds.delete(personId);
    }
    return { ...keychain, assignedPersonIds: [...assignedPersonIds] };
  }),
});

const KeychainsRoute: React.FC = () => {
  const queryKey = Key.keychains;
  const query = useQuery(queryKey, () => liveClient.getAccountKeychains());
  const optimistic = useOptimism();
  const personName = (personId: string): string =>
    query.data?.people.find(({ id }) => id === personId)?.name ?? `this person`;
  const setAssignment = useMutation(liveClient.setAccountKeychainAssignment, {
    invalidating: [queryKey],
    toast: {
      loading: ({ personId, assigned }) =>
        assigned
          ? `Assigning to ${personName(personId)}…`
          : `Removing from ${personName(personId)}…`,
      success: ({ personId, assigned }) =>
        assigned
          ? `Assigned to ${personName(personId)}`
          : `Removed from ${personName(personId)}`,
      error: `Couldn't update the keychain assignment.`,
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

  const handleAssignmentChange = (
    keychainId: string,
    personId: string,
    assigned: boolean,
  ): Promise<void> => {
    optimistic.modify(queryKey, (data) =>
      withAssignment(data, keychainId, personId, assigned),
    );
    return setAssignment
      .mutateAsync(
        { keychainId, personId, assigned },
        {
          onError: () => {
            optimistic.modify(queryKey, (data) =>
              withAssignment(data, keychainId, personId, !assigned),
            );
          },
        },
      )
      .then(() => undefined);
  };

  return <KeychainsPage state={state} onAssignmentChange={handleAssignmentChange} />;
};

export const Route = createFileRoute(`/_app/keychains/`)({
  component: KeychainsRoute,
});
