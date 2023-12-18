import React from 'react';
import { Loading, ListKeychains, ApiErrorMessage } from '@dash/components';
import { useQuery, useConfirmableDelete, Key } from '../../hooks';
import Current from '../../environment';

const Keychains: React.FC = () => {
  const query = useQuery(Key.adminKeychains, Current.api.getAdminKeychains);
  const deleteKeychain = useConfirmableDelete(`keychain`, {
    invalidating: [Key.adminKeychains],
  });

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <ListKeychains
      keychains={query.data.map((keychain) => ({
        id: keychain.summary.id,
        name: keychain.summary.name,
        isPublic: keychain.summary.isPublic,
        mode: `list`,
        removeText: `Delete`,
        description: keychain.summary.description || undefined,
        numKeys: keychain.summary.numKeys,
      }))}
      remove={deleteKeychain}
    />
  );
};

export default Keychains;
