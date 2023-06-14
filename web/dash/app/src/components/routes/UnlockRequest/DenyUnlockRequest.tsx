import React, { useState } from 'react';
import { ErrorModal, LoadingModal, Modal } from '@dash/components';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import { TextInput } from '@shared/components';
import { useMutation, useOptimism, Key, useUnlockRequest } from '../../../hooks';
import Current from '../../../environment';

const DenyUnlockRequest: React.FC = () => {
  const { id = `` } = useParams<{ id: string }>();
  const [comment, setComment] = useState(``);
  const navigate = useNavigate();
  const optimistic = useOptimism();
  const query = useUnlockRequest(id);

  const deny = useMutation(() => {
    if (query.data) {
      optimistic.update(Key.unlockRequest(id), { ...query.data, status: `rejected` });
    }
    return Current.api.updateUnlockRequest({
      id,
      status: `rejected`,
      responseComment: comment.trim() === `` ? undefined : comment,
    });
  });

  if (query.isLoading || deny.isLoading) {
    return <LoadingModal />;
  }

  if (query.isError) {
    return <ErrorModal error={query.error} />;
  }

  if (deny.isError) {
    return (
      <ErrorModal
        title="Error denying unlock request"
        error={deny.error}
        primaryButton={{ label: `Try again`, action: () => navigate(`..`) }}
      />
    );
  }

  if (deny.isSuccess) {
    return <Navigate to=".." />;
  }

  return (
    <Modal
      icon="comment"
      title="Add a comment"
      primaryButton={{
        label: <>Deny &rarr;</>,
        action: () => deny.mutate(undefined),
      }}
      secondaryButton={() => navigate(`../..`)}
    >
      <div className="mt-4">
        <TextInput
          placeholder="*optional - will be seen by your child"
          setValue={(value) => setComment(value)}
          autoFocus
          type="textarea"
          value={comment}
          testId="deny-unlock-req-comment"
        />
      </div>
    </Modal>
  );
};

export default DenyUnlockRequest;
