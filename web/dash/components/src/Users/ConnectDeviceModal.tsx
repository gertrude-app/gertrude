import React, { useState } from 'react';
import type { MacAppConnectionCode, RequestState } from '@dash/types';
import { RequestModal } from '../Modal';
import Modal from '../Modal/Modal';

interface Props {
  request?: RequestState<MacAppConnectionCode.Output>;
  dismissAddDevice(): unknown;
  onStartTrial(): unknown;
}

const ConnectDeviceModal: React.FC<Props> = ({
  dismissAddDevice,
  request,
  onStartTrial,
}) => {
  const [trialStarted, setTrialStarted] = useState(false);

  if (request?.state !== `succeeded`) {
    return (
      <RequestModal
        request={request}
        successTitle="Connection Code"
        icon="desktop"
        primaryButton={dismissAddDevice}
        onDismiss={dismissAddDevice}
        withPayload={() => null}
      />
    );
  }

  const { code, gate } = request.payload;

  if (!gate || trialStarted) {
    return (
      <Modal
        title="Connection Code"
        icon="desktop"
        isOpen
        primaryButton={dismissAddDevice}
        onDismiss={dismissAddDevice}
      >
        <ConnectionCodeContent code={code} />
      </Modal>
    );
  }

  switch (gate) {
    case `trialRequired`:
      return (
        <Modal
          title="Start Your Free Trial"
          icon="desktop"
          isOpen
          primaryButton={{
            type: `action`,
            label: `Start 21-day free trial`,
            action: () => {
              onStartTrial();
              setTrialStarted(true);
            },
          }}
          secondaryButton={dismissAddDevice}
          onDismiss={dismissAddDevice}
        >
          <TrialGateContent />
        </Modal>
      );

    case `planUpgradeRequired`:
      return (
        <Modal
          title="Upgrade Required"
          icon="desktop"
          isOpen
          primaryButton={{
            type: `link`,
            to: `/settings`,
            label: `Manage subscription`,
          }}
          secondaryButton={dismissAddDevice}
          onDismiss={dismissAddDevice}
        >
          <UpgradeRequiredContent />
        </Modal>
      );

    case `subscriptionFixRequired`:
      return (
        <Modal
          title="Subscription Inactive"
          icon="desktop"
          isOpen
          primaryButton={{
            type: `link`,
            to: `/settings`,
            label: `Manage subscription`,
          }}
          secondaryButton={dismissAddDevice}
          onDismiss={dismissAddDevice}
        >
          <SubscriptionFixContent />
        </Modal>
      );
  }
};

export default ConnectDeviceModal;

const ConnectionCodeContent: React.FC<{ code: number }> = ({ code }) => (
  <div className="space-y-3 mb-2 flex flex-col">
    <div>
      On the Mac computer you want to protect, enter the code below after launching the
      {` `}
      <b>Gertrude Mac App</b>:
    </div>
    <code
      data-test="connection-code"
      className="block text-3xl text-fuchsia-700 tracking-widest font-bold bg-fuchsia-50 w-fit self-center px-4 py-1 rounded-lg"
    >
      {code}
    </code>
    <div>
      Download the app from{` `}
      <code className="text-fuchsia-700">https://gertrude.app/download</code>.
    </div>
  </div>
);

const TrialGateContent: React.FC = () => (
  <div className="space-y-3">
    <p>
      Using the Gertrude Mac app requires a <b>Full subscription.</b>
    </p>
    <p>Try it free for 21 days with no credit card required.</p>
  </div>
);

const UpgradeRequiredContent: React.FC = () => (
  <div className="space-y-3">
    <p>
      Your free trial has ended. To continue using Gertrude on Mac computers, upgrade to a
      {` `}
      <b>Gertrude Full</b> subscription.
    </p>
  </div>
);

const SubscriptionFixContent: React.FC = () => (
  <div className="space-y-3">
    <p>
      Your subscription is currently inactive. Please update your payment information to
      continue using Mac features.
    </p>
  </div>
);
