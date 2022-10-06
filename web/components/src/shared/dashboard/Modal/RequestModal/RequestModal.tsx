import React from 'react';
import { IconType } from '../../GradientIcon/GradientIcon';
import Modal from '../Modal';

interface Props<Payload> {
  request?: RequestState<Payload>;
  successTitle: string;
  successType?: `default` | `container`;
  errorTitle?: string;
  primaryButtonText?: React.ReactNode;
  primaryButtonDisabled?: boolean;
  withPayload: (payload: Payload) => React.ReactNode;
  withError?: (error?: ApiError) => React.ReactNode;
  onPrimaryClick(): unknown;
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
  onPrimaryClick,
  primaryButtonDisabled,
  primaryButtonText,
  icon,
}: Parameters<React.FC<Props<Payload>>>[0]): ReturnType<React.FC<Props<Payload>>> {
  return (
    <Modal
      type={request?.state === `failed` ? `error` : successType}
      title={request?.state === `failed` ? errorTitle : successTitle}
      loading={request?.state === `ongoing`}
      isOpen={!!request}
      primaryButtonText={primaryButtonText}
      primaryButtonDisabled={primaryButtonDisabled}
      onPrimaryClick={onPrimaryClick}
      onDismiss={onDismiss}
      icon={icon}
    >
      {request?.state === `succeeded` ? withPayload(request.payload) : null}
      {request?.state === `failed`
        ? withError
          ? withError(request.error)
          : `Sorry, something went wrong, please try again.`
        : null}
    </Modal>
  );
}

export default RequestModal;
