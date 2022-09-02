import React, { useEffect } from 'react';
import ListKeychains from '@dashboard/Keychains/ListKeychains';
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
  const deleteId = useSelector((state) => state.admin.deleting.keychain);

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
        start: (id) => dispatch(startEntityDelete({ type: `keychain`, id })),
        confirm: () => deleteId && dispatch(deleteKeychain(deleteId)),
        cancel: () => dispatch(cancelEntityDelete(`keychain`)),
      }}
    />
  );
};

export default Keychains;
