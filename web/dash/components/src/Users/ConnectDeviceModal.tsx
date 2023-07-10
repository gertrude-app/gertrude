import React from 'react';
import type { RequestState } from '@dash/types';
import { RequestModal } from '../Modal';

interface Props {
  request?: RequestState<{ code: number }>;
  dismissAddDevice(): unknown;
}

const ConnectModal: React.FC<Props> = ({ dismissAddDevice, request }) => (
  <RequestModal
    request={request}
    successTitle="Connection Code"
    icon="desktop"
    primaryButton={dismissAddDevice}
    onDismiss={dismissAddDevice}
    withPayload={(payload) => (
      <div className="space-y-3 mb-2 flex flex-col">
        <div>
          Enter the code below into the <i>Gertrude Mac App</i>:
        </div>
        <code className="block text-3xl text-fuchsia-700 tracking-widest font-bold bg-fuchsia-50 w-fit self-center px-4 py-1 rounded-lg">
          {payload.code}
        </code>
        <div>
          The device will show up in the list <em>once it has connected.</em>
        </div>
      </div>
    )}
  />
);

export default ConnectModal;
