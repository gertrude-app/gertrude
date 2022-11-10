import React from 'react';
import { Navigate, useNavigate, useParams } from 'react-router-dom';
import { Modal, KeychainPicker, LoadingModal } from '@dash/components';
import useSelectableKeychains from '../../../hooks/selectable-keychains';
import UnexpectedError from '../../UnexpectedError';
import { useUnlockRequestLoader } from '../loaders/unlock-request';
import { useUserLoader } from '../loaders/user';
import { useCombinedLoaders } from '../loaders/combined';
import { useDispatch, useSelector } from '../../../redux/hooks';
import { keychainSelected } from '../../../redux/slice-unlock-requests';
import { unlockRequestReviewKeyClicked } from '../../../redux/slice-keychains';

const SelectUnlockRequestKeychain: React.FC = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const params = useParams<{ unlockRequestId: UUID; userId: UUID }>();
  const keychainsReq = useSelectableKeychains();

  const { adminId, selectedId } = useSelector((state) => ({
    adminId: state.auth.admin?.id ?? ``,
    selectedId: state.unlockRequests.selectedKeychainId,
  }));

  const loader = useCombinedLoaders(
    useUnlockRequestLoader,
    [params.unlockRequestId ?? ``],
    useUserLoader,
    [params.userId ?? ``],
  );

  if (loader.state === `unresolved`) {
    return loader.element;
  }

  const [unlockRequest, user] = loader.entity;
  if (unlockRequest.status !== `pending`) {
    return <Navigate to=".." />;
  }

  if (keychainsReq.state === `ongoing` || keychainsReq.state === `idle`) {
    return <LoadingModal />;
  }

  if (keychainsReq.state === `failed`) {
    return <UnexpectedError id="3b65a1b7" />;
  }

  const keychains = keychainsReq.payload;
  const userKeychainIds = user.original.keychains.map((keychain) => keychain.id);
  const selectableKeychains = keychains.own
    .filter((keychain) => userKeychainIds.includes(keychain.id))
    .concat(keychains.public.filter((keychain) => keychain.authorId === adminId));

  return (
    <Modal
      type="container"
      icon="key"
      title="Select a keychain"
      secondaryButton={{
        label: <>&larr; Back</>,
        action: () => navigate(`../review`),
      }}
      primaryButton={{
        label: <>Review key &rarr;</>,
        disabled: !selectedId,
        action: () => {
          dispatch(
            unlockRequestReviewKeyClicked({
              keychainId: selectedId ?? ``,
              unlockRequest,
            }),
          );
          navigate(`../edit-key`);
        },
      }}
    >
      <KeychainPicker
        hasNoOwnKeychains={keychains.own.length === 0}
        selectableOwnKeychains={selectableKeychains}
        includePublic={false}
        selectablePublicKeychains={[]}
        onSelect={(keychain) => dispatch(keychainSelected(keychain.id))}
        selectedId={selectedId}
      />
    </Modal>
  );
};

export default SelectUnlockRequestKeychain;
