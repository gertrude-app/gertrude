import React from 'react';
import type { RequestState } from '@dash/types';
import type { IconType } from '../GradientIcon';
import Modal from './Modal';
import { ErrorModal } from '.';

interface Props<Payload> {
  request?: RequestState<Payload>;
  successTitle: string;
  successType?: `default` | `container`;
  errorTitle?: string;
  primaryButton: React.ComponentProps<typeof Modal>[`primaryButton`];
  withPayload: (payload: Payload) => React.ReactNode;
  onDismiss(): unknown;
  icon?: IconType;
}

function RequestModal<Payload>({
  request,
  successTitle,
  successType = `default`,
  errorTitle = `Error`,
  withPayload,
  onDismiss,
  primaryButton,
  icon,
}: Props<Payload>): ReturnType<React.FC<Props<Payload>>> {
  if (request?.state === `failed`) {
    return (
      <ErrorModal
        title={errorTitle}
        primaryButton={primaryButton}
        error={request.error}
        onDismiss={onDismiss}
      />
    );
  }
  return (
    <Modal
      type={successType}
      title={successTitle}
      loading={request?.state === `ongoing`}
      isOpen={!!request && request.state !== `idle`}
      primaryButton={primaryButton}
      secondaryButton={onDismiss}
      icon={icon}
    >
      {request?.state === `succeeded` ? withPayload(request.payload) : null}
    </Modal>
  );
}

export default RequestModal;
