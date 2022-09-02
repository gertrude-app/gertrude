import React, { useEffect } from 'react';
import ListKeychains from '@shared/dashboard/Keychains/ListKeychains';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import {
  cancelEntityDelete,
  deleteKeychain,
  fetchAdminKeychains,
  startEntityDelete,
} from '../../redux/slice-admin';

const Keychains: React.FC = () => {
  const dispatch = useDispatch();
  const request = useSelector((state) => state.admin.listKeychainsRequest);
  const deleteId = useSelector((state) => state.admin.pendingDeletionKeychainId);

  useEffect(() => {
    dispatch(fetchAdminKeychains());
  }, [dispatch]);

  if (request.state === `ongoing` || request.state === `idle`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <ListKeychains
      keychains={request.payload.map((keychain) => ({
        ...keychain,
        description: keychain.description || undefined,
        keys: keychain.keys.length,
      }))}
      remove={{
        id: deleteId,
        start: (id) => dispatch(startEntityDelete({ type: `Keychain`, id })),
        confirm: () => deleteId && dispatch(deleteKeychain(deleteId)),
        cancel: () => dispatch(cancelEntityDelete(`Keychain`)),
      }}
    />
  );
};

export default Keychains;
