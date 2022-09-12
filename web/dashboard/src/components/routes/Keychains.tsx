import React, { useEffect } from 'react';
import ListKeychains from '@dashboard/Keychains/ListKeychains';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import {
  cancelKeychainEntityDelete,
  deleteKeychain,
  fetchAdminKeychains,
  startKeychainEntityDelete,
} from '../../redux/slice-keychains';

const Keychains: React.FC = () => {
  const dispatch = useDispatch();
  const request = useSelector((state) => state.keychains.listKeychainsRequest);
  const deleteId = useSelector((state) => state.keychains.deleting.keychain);

  const reqState = request.state;
  useEffect(() => {
    reqState === `idle` && dispatch(fetchAdminKeychains());
  }, [dispatch, reqState]);

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
        start: (id) => dispatch(startKeychainEntityDelete({ type: `keychain`, id })),
        confirm: () => deleteId && dispatch(deleteKeychain(deleteId)),
        cancel: () => dispatch(cancelKeychainEntityDelete(`keychain`)),
      }}
    />
  );
};

export default Keychains;
