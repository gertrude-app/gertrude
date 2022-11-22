import React from 'react';
import { Modal } from '@dash/components';
import { useNavigate } from 'react-router-dom';
import { TextInput } from '@shared/components';
import { useDispatch, useSelector } from '../../../redux/hooks';
import { denyCommentUpdated } from '../../../redux/slice-unlock-requests';

const DenyUnlockRequestComment: React.FC = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();
  const comment = useSelector((state) => state.unlockRequests.denyComment);
  return (
    <Modal
      icon="comment"
      title="Add a comment"
      primaryButton={{
        label: <>Deny &rarr;</>,
        action: () => navigate(`../deny`),
      }}
      secondaryButton={() => navigate(`../..`)}
    >
      <div className="mt-4">
        <TextInput
          placeholder="*optional - will be seen by your child"
          setValue={(value) => dispatch(denyCommentUpdated(value))}
          autoFocus
          type="textarea"
          value={comment ?? ``}
          testId="deny-unlock-req-comment"
        />
      </div>
    </Modal>
  );
};

export default DenyUnlockRequestComment;
