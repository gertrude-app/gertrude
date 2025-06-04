import { Modal } from '@dash/components';
import React from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import Current from '../../environment';
import { useFireAndForget } from '../../hooks';

const CheckoutCancel: React.FC = () => {
  const [params] = useSearchParams();
  const sessionId = params.get(`session_id`) ?? ``;
  const navigate = useNavigate();

  useFireAndForget(() =>
    Current.api.handleCheckoutCancel({ stripeCheckoutSessionId: sessionId }),
  );

  return (
    <Modal
      title="Payment setup cancelled"
      type="error"
      icon="exclamation-triangle"
      isOpen
      primaryButton={{
        label: `Back to settings →`,
        action: () => navigate(`/settings`),
      }}
      secondaryButton={{
        label: `Contact support`,
        action: () => (window.location.href = `https://gertrude.app/contact`),
      }}
      onDismiss={() => navigate(`/settings`)}
    >
      The checkout process was cancelled. Please contact support if this was not your
      intention, or if you are having any kind of trouble setting up payment.
    </Modal>
  );
};

export default CheckoutCancel;
