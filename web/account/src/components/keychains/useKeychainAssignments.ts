import type { AssignablePerson } from '#/components/types';
import type { GetAccountKeychains } from '@shared/pairql/src/account';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism } from '#/pairql/query';

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

export default function useKeychainAssignments(
  people: AssignablePerson[],
): (keychainId: string, personId: string, assigned: boolean) => Promise<void> {
  const optimistic = useOptimism();
  const personName = (personId: string): string =>
    people.find(({ id }) => id === personId)?.name ?? `this person`;
  const setAssignment = useMutation(liveClient.setAccountKeychainAssignment, {
    invalidating: [Key.keychains, Key.people, Key.unlockRequests, Key.securityEvents],
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

  return (keychainId, personId, assigned) => {
    const person = people.find(({ id }) => id === personId);
    const updateAssignment = (assigned: boolean): void => {
      optimistic.modify(Key.keychains, (data) =>
        withAssignment(data, keychainId, personId, assigned),
      );
      optimistic.modify(Key.keychain(keychainId), (data) => {
        const assignedPeople = data.assignedPeople.filter(({ id }) => id !== personId);
        return {
          ...data,
          assignedPeople:
            assigned && person ? [...assignedPeople, person] : assignedPeople,
        };
      });
    };

    updateAssignment(assigned);
    return setAssignment
      .mutateAsync(
        { keychainId, personId, assigned },
        { onError: () => updateAssignment(!assigned) },
      )
      .then(() => undefined);
  };
}
