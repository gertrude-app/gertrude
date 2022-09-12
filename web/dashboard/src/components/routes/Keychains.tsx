import React, { useEffect } from 'react';
import { v4 as uuid } from 'uuid';
import ListKeychains from '@dashboard/Keychains/List';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import * as typesafe from '../../lib/typesafe';
import {
  cancelKeychainEntityDelete,
  createKeychainInitiated,
  deleteKeychain,
  fetchAdminKeychains,
  startKeychainEntityDelete,
} from '../../redux/slice-keychains';

const Keychains: React.FC = () => {
  const dispatch = useDispatch();
  const adminId = useSelector((state) => state.auth.admin?.id ?? ``);
  const request = useSelector((state) => state.keychains.listAdminKeychainsRequest);
  const deleteId = useSelector((state) => state.keychains.deleting.keychain);
  const keychains = useSelector((state) =>
    typesafe.objectValues(state.keychains.adminKeychains),
  );

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
      keychains={keychains.map((keychain) => ({
        ...keychain.original,
        description: keychain.original.description || undefined,
        keys: keychain.original.keys.length,
      }))}
      remove={{
        id: deleteId,
        start: (id) => dispatch(startKeychainEntityDelete({ type: `keychain`, id })),
        confirm: () => deleteId && dispatch(deleteKeychain(deleteId)),
        cancel: () => dispatch(cancelKeychainEntityDelete(`keychain`)),
      }}
      onCreateNew={() => dispatch(createKeychainInitiated({ id: uuid(), adminId }))}
    />
  );
};

export default Keychains;
