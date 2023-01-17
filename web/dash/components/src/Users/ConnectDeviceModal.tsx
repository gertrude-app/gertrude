import React from 'react';
import type { RequestState } from '@dash/types';
import { RequestModal } from '../Modal';

interface Props {
  request?: RequestState<number>;
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
      <div className="space-y-3 mb-2">
        <div>
          Enter the code below into the <i>Gertrude Mac App</i>:
        </div>
        <code className="block text-3xl text-green-700 tracking-widest block text-center">
          {payload}
        </code>
        <div>
          The device will show up in the list <em>once it has connected.</em>
        </div>
      </div>
    )}
  />
);

export default ConnectModal;
