import React, { useEffect } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { Loading, EditKeychain, ApiErrorMessage } from '@dash/components';
import { toKeyRecord } from '@dash/keys';
import type { QueryProps } from '../../redux/store';
import { useDispatch, useSelector } from '../../redux/hooks';
import { isDirty, original, Query, Req } from '../../redux/helpers';
import * as typesafe from '../../lib/typesafe';
import useApps from '../../hooks/apps';
import {
  fetchAdminKeychain,
  keychainDescriptionUpdated,
  keychainNameUpdated,
  upsertKeychain,
  keychainEntityDeleteCanceled,
  keychainEntityDeleteStarted,
  deleteKeychain,
  deleteKeyRecord,
  editKeyEventReceived,
  createNewKeyClicked,
  editKeyModalDismissed,
  editKeyClicked,
  upsertEditingKeyRecord,
} from '../../redux/slice-keychains';

const Keychain: React.FC = () => {
  const { keychainId: id = `` } = useParams<{ keychainId: string }>();
  const dispatch = useDispatch();
  const appsReq = useApps();
  const [keychainQuery, shouldFetchKeychain] = useSelector(queryProps(dispatch, id));

  useEffect(() => {
    shouldFetchKeychain && dispatch(fetchAdminKeychain(id));
  }, [dispatch, id, shouldFetchKeychain]);

  if (keychainQuery.state === `entityDeleted`) {
    return <Navigate to={keychainQuery.redirectUrl} />;
  }

  if (appsReq.state === `idle` || appsReq.state === `ongoing`) {
    return <Loading />;
  }

  if (keychainQuery.state === `shouldFetch` || keychainQuery.state === `ongoing`) {
    return <Loading />;
  }

  if (appsReq.state === `failed`) {
    return <ApiErrorMessage error={appsReq.error} />;
  }

  if (keychainQuery.state === `failed`) {
    return <ApiErrorMessage error={keychainQuery.error} />;
  }

  return <EditKeychain {...keychainQuery.props} apps={appsReq.payload} />;
};

export default Keychain;

export const queryProps: QueryProps<typeof EditKeychain, UUID> =
  (dispatch, id) => (state) => {
    const keychain = state.keychains.keychains[id];
    const fetchReq = state.keychains.fetchAdminKeychainRequest[id];
    const updateReq = state.keychains.updateAdminKeychainRequest[id];
    const deleting = state.keychains.deleting;
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
          id: deleting.keychain,
          start: () => dispatch(keychainEntityDeleteStarted({ type: `keychain`, id })),
          cancel: () => dispatch(keychainEntityDeleteCanceled(`keychain`)),
          confirm: () => dispatch(deleteKeychain(id)),
        },
        deleteKey: {
          id: deleting.key,
          start: (id) => dispatch(keychainEntityDeleteStarted({ type: `key`, id })),
          cancel: () => dispatch(keychainEntityDeleteCanceled(`key`)),
          confirm: () => dispatch(deleteKeyRecord(deleting.key ?? ``)),
        },
        apps: [],
      }),
      false,
    ];
  };
