import { ApiErrorMessage, Loading } from '@dash/components';
import { EditKeychain } from '@dash/components';
import { toKeyRecord } from '@dash/keys';
import { Result } from '@dash/types';
import React, { useEffect, useMemo, useReducer } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import type { KeychainSummary } from '@dash/types';
import Current from '../../environment';
import { Key, useConfirmableDelete, useMutation, useQuery } from '../../hooks';
import { useAuth } from '../../hooks/auth';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/edit-keychain-reducer';

const Keychain: React.FC = () => {
  const { keychainId: id = `` } = useParams<{ keychainId: string }>();
  const { admin } = useAuth();
  const [state, dispatch] = useReducer(reducer, { keys: [] });
  const editableKeychain = state.keychain;
  const queryKey = Key.adminKeychain(id);
  const appsQuery = useQuery(Key.apps, Current.api.getIdentifiedApps);
  const deleteKeychain = useConfirmableDelete(`keychain`, { id });
  const deleteKey = useConfirmableDelete(`key`, { invalidating: [queryKey] });

  const newKeychainId = useMemo(() => uuid(), []);
  useEffect(() => {
    if (id === `new`) {
      dispatch({
        type: `createNewKeychain`,
        id: newKeychainId,
        adminId: admin?.id ?? ``,
      });
    }
  }, [newKeychainId, id, admin, dispatch]);

  const keychainQuery = useQuery(queryKey, () => Current.api.getAdminKeychain(id), {
    onReceive: (keychain) => dispatch({ type: `receivedKeychain`, keychain }),
    enabled: id !== `new` && state.keychain?.isNew !== true,
  });

  const saveKeychain = useMutation(
    (keychain: Editable<KeychainSummary>) =>
      Current.api.saveKeychain({
        isNew: keychain.isNew ?? false,
        id: keychain.draft.id,
        name: keychain.draft.name,
        description: keychain.draft.description,
      }),
    {
      onSuccess: () => dispatch({ type: `keychainSaved` }),
      toast: `save:keychain`,
      invalidating: [queryKey],
    },
  );

  const saveKey = useMutation(
    () => {
      const keyRecord = toKeyRecord(state.editingKey);
      if (!keyRecord) return Result.resolveUnexpected(`aa11e7f2`);
      return Current.api.saveKey({
        isNew: state.editingKey?.isNew ?? false,
        id: keyRecord.id,
        keychainId: keyRecord.keychainId,
        key: keyRecord.key,
        comment: keyRecord.comment,
        expiration: keyRecord.expiration,
      });
    },
    {
      toast: `save:key`,
      onSuccess: () => dispatch({ type: `keySaved` }),
      invalidating: [queryKey],
    },
  );

  if (id === `new`) {
    return <Navigate to={`/keychains/${newKeychainId}`} replace />;
  }

  if (deleteKeychain.state === `success`) {
    return <Navigate to="/keychains" />;
  }

  if (keychainQuery.isError) {
    return <ApiErrorMessage error={keychainQuery.error} />;
  }

  if (appsQuery.isError) {
    return <ApiErrorMessage error={appsQuery.error} />;
  }

  if (!editableKeychain || !appsQuery.data) {
    return <Loading />;
  }

  return (
    <EditKeychain
      isNew={editableKeychain.isNew ?? false}
      apps={appsQuery.data}
      name={editableKeychain.draft.name}
      description={editableKeychain.draft.description ?? ``}
      keys={state.keys}
      editingKey={state.editingKey}
      setName={(name) => dispatch({ type: `updateName`, name })}
      setDescription={(description) => dispatch({ type: `updateDesc`, description })}
      deleteKeychain={deleteKeychain}
      deleteKey={deleteKey}
      saveButtonDisabled={saveKeychain.isPending || !isDirty(editableKeychain)}
      onSave={() => saveKeychain.mutate(editableKeychain)}
      beginEditKey={(id) => dispatch({ type: `beginEditKey`, id })}
      updateEditingKey={(event) => dispatch({ type: `updateEditingKey`, event })}
      dismissEditKeyModal={() => dispatch({ type: `cancelEditKey` })}
      onKeySave={() => saveKey.mutate(undefined)}
      onCreateNewKey={() => dispatch({ type: `createNewKey` })}
      keyModalSaveButtonDisabled={
        toKeyRecord(state.editingKey) === null || saveKey.isPending
      }
    />
  );
};

export default Keychain;
