import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import { fetchAdminKeychains } from '../../redux/slice-admin';
import ListKeychains from '@shared/dashboard/Keychains/ListKeychains';

const Keychains: React.FC = () => {
  const dispatch = useDispatch();
  const request = useSelector((state) => state.admin.listKeychainsRequest);

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
      removeKeychain={() => {}}
    />
  );
};

export default Keychains;
