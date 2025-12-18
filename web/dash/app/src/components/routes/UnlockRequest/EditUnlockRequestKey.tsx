import { ErrorModal, KeyCreator, LoadingModal, Modal } from '@dash/components';
import { convert, toKeyRecord } from '@dash/keys';
import { Result } from '@shared/pairql';
import React, { useState } from 'react';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import type { EditKey } from '@dash/keys';
import Current from '../../../environment';
import { Key, useApps, useMutation, useQuery, useZip } from '../../../hooks';
import editKeyReducer from '../../../reducers/edit-key-reducer';

const EditUnlockRequestKey: React.FC = () => {
  const { id = ``, keychainId = `` } = useParams<{ id: string; keychainId: string }>();
  const [key, setKey] = useState<EditKey.State | null>(null);
  const navigate = useNavigate();

  const query = useZip(
    useApps(),
    useQuery(Key.unlockRequest(id), () => Current.api.getUnlockRequest(id), {
      onReceive: (unlockRequest) =>
        setKey(convert.unlockRequestToState(uuid(), keychainId, unlockRequest)),
    }),
  );

  const accept = useMutation(async (key: EditKey.State) => {
    const keyRecord = convert.toKeyRecord(key);
    if (!keyRecord) return Result.resolveUnexpected(`76cfc4ee`);
    const insert = await Current.api.saveKey({ isNew: true, ...keyRecord });
    if (insert.isError) return insert;
    // TODO: make an `AcceptUnlockRequest` pair, to combine these
    return Current.api.updateUnlockRequest({ id, status: `accepted` });
  });

  if (accept.isError) {
    return (
      <ErrorModal
        title="Error accepting unlock request"
        error={accept.error}
        primaryButton={{ label: `Try again`, action: () => navigate(`..`) }}
      />
    );
  }

  if (query.isError) {
    return <ErrorModal error={query.error} />;
  }

  if (query.isPending || accept.isPending || !key) {
    return <LoadingModal />;
  }

  if (accept.isSuccess) {
    return <Navigate to=".." />;
  }

  return (
    <Modal
      icon="key"
      type="container"
      title="Review/edit unlocking key"
      onDismiss={() => navigate(`../..`)}
      secondaryButton={{
        label: <>&larr; Back</>,
        action: () => navigate(`../select-keychain`),
      }}
      primaryButton={{
        label: <>Submit &rarr;</>,
        action: () => accept.mutate(key),
        disabled: toKeyRecord(key) === null,
      }}
    >
      <div className="px-2">
        <KeyCreator
          {...key}
          update={(event) => {
            editKeyReducer(key, event);
            setKey({ ...key });
          }}
          apps={query.data[0]}
        />
      </div>
    </Modal>
  );
};

export default EditUnlockRequestKey;
