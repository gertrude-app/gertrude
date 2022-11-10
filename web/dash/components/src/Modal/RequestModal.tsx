import React from 'react';
import type { IconType } from '../GradientIcon';
import Modal from './Modal';
import { ErrorModal } from '.';

interface Props<Payload> {
  request?: RequestState<Payload>;
  successTitle: string;
  successType?: `default` | `container`;
  errorTitle?: string;
  primaryButton: React.ComponentProps<typeof Modal>['primaryButton'];
  withPayload: (payload: Payload) => React.ReactNode;
  withError?: (error?: ApiError) => React.ReactNode;
  onDismiss(): unknown;
  icon?: IconType;
}

function RequestModal<Payload>({
  request,
  successTitle,
  successType = `default`,
  errorTitle = `Error`,
  withError,
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
        nonActionableMessage={withError?.(request.error)}
      />
    );
  }
  return (
    <Modal
      type={successType}
      title={successTitle}
      loading={request?.state === `ongoing`}
      isOpen={!!request}
      primaryButton={primaryButton}
      secondaryButton={onDismiss}
      icon={icon}
    >
      {request?.state === `succeeded` ? withPayload(request.payload) : null}
    </Modal>
  );
}

export default RequestModal;
