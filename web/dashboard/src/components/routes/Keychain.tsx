import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import EditKeychain from '@dashboard/Keychains/Edit';
import { QueryProps } from '../../redux/store';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import Loading from '../shared/Loading';
import { isDirty, Query, Req } from '../../redux/helpers';
import {
  fetchAdminKeychain,
  keychainDescriptionUpdated,
  keychainNameUpdated,
  upsertKeychain,
  keychainEntityDeleteCanceled,
  keychainEntityDeleteStarted,
  deleteKeychain,
} from '../../redux/slice-keychains';

const Keychain: React.FC = () => {
  const { keychainId: id = `` } = useParams<{ keychainId: string }>();
  const dispatch = useDispatch();
  const [query, shouldFetch] = useSelector(queryProps(dispatch, id));

  useEffect(() => {
    shouldFetch && dispatch(fetchAdminKeychain(id));
  }, [dispatch, id, shouldFetch]);

  if (query.state === `shouldFetch` || query.state === `ongoing`) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <EditKeychain {...query.props} />;
};

export default Keychain;

export const queryProps: QueryProps<typeof EditKeychain, UUID> =
  (dispatch, id) => (state) => {
    const keychain = state.keychains.adminKeychains[id];
    const fetchReq = state.keychains.fetchAdminKeychainRequest[id];
    const updateReq = state.keychains.updateAdminKeychainRequest[id];
    const deleteId = state.keychains.deleting.keychain;

    if (!keychain && fetchReq?.state !== `succeeded`) {
      return [Req.toUnresolvedQuery(fetchReq), fetchReq?.state !== `failed`];
    }

    if (!keychain) {
      // we get in this state briefly after a keychain is deleted
      return [{ state: `ongoing` }, false];
    }

    return [
      Query.resolve({
        isNew: keychain.isNew ?? false,
        name: keychain.draft.name,
        description: keychain.draft.description ?? ``,
        keys: keychain.draft.keys,
        setName: (name) => dispatch(keychainNameUpdated({ id, name })),
        setDescription: (description) =>
          dispatch(keychainDescriptionUpdated({ id, description })),
        onSave: () => dispatch(upsertKeychain(id)),
        saveButtonDisabled:
          updateReq?.state === `ongoing` || (keychain.isNew ? false : !isDirty(keychain)),
        deleteKeychain: {
          id: deleteId,
          start: () => dispatch(keychainEntityDeleteStarted({ type: `keychain`, id })),
          cancel: () => dispatch(keychainEntityDeleteCanceled(`keychain`)),
          confirm: () => dispatch(deleteKeychain(id)),
        },
      }),
      false,
    ];
  };
