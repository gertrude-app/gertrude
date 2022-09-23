import React, { useEffect } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import EditKeychain from '@dashboard/Keychains/Edit';
import { QueryProps } from '../../redux/store';
import { useDispatch, useSelector } from '../../redux/hooks';
import ApiErrorMessage from '../ApiErrorMessage';
import Loading from '../shared/Loading';
import { isDirty, original, Query, Req } from '../../redux/helpers';
import * as typesafe from '../../lib/typesafe';
import {
  fetchAdminKeychain,
  keychainDescriptionUpdated,
  keychainNameUpdated,
  upsertKeychain,
  keychainEntityDeleteCanceled,
  keychainEntityDeleteStarted,
  deleteKeychain,
  editKeyEventReceived,
  createNewKeyClicked,
  editKeyModalDismissed,
  editKeyClicked,
  upsertEditingKeyRecord,
} from '../../redux/slice-keychains';
import { toKeyRecord } from '../shared/dashboard/lib/keys/convert';

const Keychain: React.FC = () => {
  const { keychainId: id = `` } = useParams<{ keychainId: string }>();
  const dispatch = useDispatch();
  const [query, shouldFetch] = useSelector(queryProps(dispatch, id));

  useEffect(() => {
    shouldFetch && dispatch(fetchAdminKeychain(id));
  }, [dispatch, id, shouldFetch]);

  if (query.state === `entityDeleted`) {
    return <Navigate to={query.redirectUrl} />;
  }

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
    const keychain = state.keychains.keychains[id];
    const fetchReq = state.keychains.fetchAdminKeychainRequest[id];
    const updateReq = state.keychains.updateAdminKeychainRequest[id];
    const deletingId = state.keychains.deleting.keychain;
    const editingKey = state.keychains.editingKey;

    if (state.keychains.deleted.includes(id)) {
      return [Query.redirectDeleted(`/keychains`), false];
    }

    if (!keychain && fetchReq?.state !== `succeeded`) {
      return [Req.toUnresolvedQuery(fetchReq), fetchReq?.state !== `failed`];
    }

    if (!keychain) {
      return [Query.unexpectedError(), false];
    }

    return [
      Query.resolve({
        isNew: keychain.isNew ?? false,
        name: keychain.draft.name,
        description: keychain.draft.description ?? ``,
        keys: typesafe
          .objectValues(state.keychains.keyRecords)
          .filter((editable) => !editable.isNew && editable.original.keychainId === id)
          .map(original),
        setName: (name) => dispatch(keychainNameUpdated({ id, name })),
        setDescription: (description) =>
          dispatch(keychainDescriptionUpdated({ id, description })),
        onSave: () => dispatch(upsertKeychain(id)),
        editingKey,
        updateEditingKey: (event) => dispatch(editKeyEventReceived(event)),
        dismissEditKeyModal: () => dispatch(editKeyModalDismissed()),
        onCreateNewKey: () => dispatch(createNewKeyClicked(id)),
        beginEditKey: (keyId) => dispatch(editKeyClicked(keyId)),
        onKeySave: () => dispatch(upsertEditingKeyRecord()),
        keyModalSaveButtonDisabled:
          toKeyRecord(editingKey) === null ||
          state.keychains.saveKeyRecordRequest.state === `ongoing`,
        saveButtonDisabled:
          updateReq?.state === `ongoing` || (keychain.isNew ? false : !isDirty(keychain)),
        deleteKeychain: {
          id: deletingId,
          start: () => dispatch(keychainEntityDeleteStarted({ type: `keychain`, id })),
          cancel: () => dispatch(keychainEntityDeleteCanceled(`keychain`)),
          confirm: () => dispatch(deleteKeychain(id)),
        },
      }),
      false,
    ];
  };
