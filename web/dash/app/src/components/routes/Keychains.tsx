import { ApiErrorMessage, ListKeychains, Loading } from '@dash/components';
import React from 'react';
import Current from '../../environment';
import { Key, useConfirmableDelete, useMutation, useQuery } from '../../hooks';

const Keychains: React.FC = () => {
  const adminKeychainsQuery = useQuery(Key.adminKeychains, Current.api.getAdminKeychains);
  const deleteKeychain = useConfirmableDelete(`keychain`, {
    invalidating: [Key.adminKeychains],
  });
  const toggleChildKeychain = useMutation(
    (data: { childId: string; keychainId: string }) =>
      Current.api.toggleChildKeychain(data),
    {
      toast: `save:user`,
      onSuccess: () => {
        adminKeychainsQuery.refetch();
      },
    },
  );

  if (adminKeychainsQuery.isPending) {
    return <Loading />;
  }

  if (adminKeychainsQuery.isError) {
    return <ApiErrorMessage error={adminKeychainsQuery.error} />;
  }

  return (
    <ListKeychains
      keychains={adminKeychainsQuery.data.keychains.map((keychain) => ({
        id: keychain.summary.id,
        name: keychain.summary.name,
        assignedChildren: keychain.children,
        allChildren: adminKeychainsQuery.data.children,
        isPublic: keychain.summary.isPublic,
        mode: `keychains_screen`,
        description: keychain.summary.description || undefined,
        numKeys: keychain.summary.numKeys,
        toggleChild: (childId: string) => {
          toggleChildKeychain.mutate({
            childId,
            keychainId: keychain.summary.id,
          });
        },
      }))}
      remove={deleteKeychain}
    />
  );
};

export default Keychains;
