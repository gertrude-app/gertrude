import React from 'react';
import type { IOSAppConnectionCode, RequestState } from '@dash/types';
import { RequestModal } from '../Modal';
import Modal from '../Modal/Modal';

interface Props {
  request?: RequestState<IOSAppConnectionCode.Output>;
  dismissModal(): unknown;
  childName: string;
}

const ConnectIOSAppModal: React.FC<Props> = ({ request, dismissModal, childName }) => {
  if (request?.state !== `succeeded`) {
    return (
      <RequestModal
        request={request}
        successTitle="Connection Code"
        icon="phone"
        primaryButton={dismissModal}
        onDismiss={dismissModal}
        withPayload={() => null}
      />
    );
  }

  return (
    <Modal
      title="Connection Code"
      icon="phone"
      isOpen
      primaryButton={dismissModal}
      onDismiss={dismissModal}
    >
      <div className="space-y-3 mb-2 flex flex-col">
        <div>
          Download the <b>Gertrude Blocker</b> app on an iPhone or iPad, then when
          prompted, enter the code below to connect it to {childName}:
        </div>
        <code className="block text-3xl text-fuchsia-700 tracking-widest font-bold bg-fuchsia-50 w-fit self-center px-4 py-1 rounded-lg">
          {request.payload.code}
        </code>
      </div>
    </Modal>
  );
};

export default ConnectIOSAppModal;
