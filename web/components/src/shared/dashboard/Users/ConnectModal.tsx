import React from 'react';
import RequestModal from '../Modal/RequestModal';

interface Props {
  request?: RequestState<UUID>;
  dismissAddDevice(): unknown;
}

const ConnectModal: React.FC<Props> = ({ dismissAddDevice, request }) => (
  <RequestModal
    request={request}
    successTitle="Connection Token"
    icon="desktop"
    onPrimaryClick={dismissAddDevice}
    onDismiss={dismissAddDevice}
    withPayload={(payload) => (
      <div className="space-y-3 mb-2">
        <div>
          Copy the token shown below, and paste it into the <i>Gertrude Mac App</i> to
          connect the device.
        </div>
        <code className="block text-green-700">{payload}</code>
        <div>
          The device will show up in the list <em>once it has connected.</em>
        </div>
      </div>
    )}
  />
);

export default ConnectModal;
