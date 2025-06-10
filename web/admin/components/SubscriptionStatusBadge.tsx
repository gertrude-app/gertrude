import cx from 'classnames';
import React from 'react';
import type { AdminData } from '@/lib/types';

const SubscriptionStatusBadge: React.FC<{
  status: AdminData[`subscriptionStatus`];
}> = ({ status }) => {
  const statusColors = {
    pendingEmailVerification: `bg-yellow-200 text-yellow-800`,
    trialing: `bg-blue-100 text-blue-800`,
    trialExpiringSoon: `bg-orange-200 text-orange-800`,
    overdue: `bg-pink-200 text-pink-800`,
    paid: `bg-green-200 text-green-800`,
    unpaid: `bg-red-200 text-red-800`,
    pendingAccountDeletion: `bg-gray-200 text-gray-800`,
    complimentary: `bg-violet-200 text-violet-800`,
  };

  return (
    <div
      className={cx(
        `uppercase text-xs font-medium py-1 px-4 rounded-full w-fit`,
        statusColors[status],
      )}
    >
      {statusText(status)}
    </div>
  );
};

export default SubscriptionStatusBadge;

function statusText(status: AdminData[`subscriptionStatus`]): string {
  switch (status) {
    case `pendingEmailVerification`:
      return `Pending email verification`;
    case `trialing`:
      return `Trialing`;
    case `trialExpiringSoon`:
      return `Trial expiring soon`;
    case `overdue`:
      return `Overdue`;
    case `paid`:
      return `Paid`;
    case `unpaid`:
      return `Unpaid`;
    case `pendingAccountDeletion`:
      return `Pending account deletion`;
    case `complimentary`:
      return `Complimentary`;
  }
}
