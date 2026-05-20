import { Modal } from '@dash/components';
import React from 'react';
import { useDashboardStale } from '../stale-dashboard';

const StaleDashboardReload: React.FC = () => {
  const isStale = useDashboardStale();
  if (!isStale) return null;

  return (
    <Modal
      title="Dashboard updated"
      icon="lightning-bolt"
      primaryButton={{
        type: `action`,
        action: () => window.location.reload(),
        label: `Reload dashboard`,
      }}
    >
      Gertrude has been updated. Reload the dashboard to keep working.
    </Modal>
  );
};

export default StaleDashboardReload;
