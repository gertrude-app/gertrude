import { Button, ConfirmationDialog } from '@gertrude/ui';
import { XIcon } from 'lucide-react';
import React from 'react';
import type { NotificationMethod } from '#/components/types';
import {
  notificationMethodIcon,
  notificationMethodSelectLabel,
  notificationMethodTarget,
} from './notificationMethodUtils';

type Props = {
  method: NotificationMethod;
  notificationCount: number;
  onDelete: () => void;
};

const NotificationMethodChip: React.FC<Props> = ({
  method,
  notificationCount,
  onDelete,
}) => (
  <div className="flex items-center rounded-xl border border-stone-200 bg-white p-1.5 pl-3 shadow shadow-stone-300/30">
    {notificationMethodIcon(method)}
    {methodLabel(method)}
    <ConfirmationDialog
      confirmationQuestion="Delete notification method?"
      description={methodDeleteDescription(notificationCount)}
      trigger={
        <Button
          type="button"
          onClick={() => {}}
          ariaLabel={`Delete ${notificationMethodSelectLabel(method)}`}
          size="small"
          variant="ghost"
          icon={XIcon}
          className="ml-2"
        />
      }
      actions={[
        { text: `Cancel` },
        {
          text: `Delete method`,
          icon: XIcon,
          variant: `destructive`,
          onClick: onDelete,
        },
      ]}
    />
  </div>
);

export default NotificationMethodChip;

function methodLabel(method: NotificationMethod): React.ReactNode {
  const baseClasses = `ml-2.5 text-stone-600`;
  const targetClasses = `rounded border-[0.5px] border-stone-300 bg-stone-100 px-1 py-0.25 font-medium text-stone-900`;
  const target = notificationMethodTarget(method);

  switch (method.type) {
    case `email`:
      return (
        <span className={baseClasses}>
          Email <span className={targetClasses}>{target}</span>
        </span>
      );
    case `text`:
      return (
        <span className={baseClasses}>
          Text <span className={targetClasses}>{target}</span>
        </span>
      );
    case `slack`:
      return (
        <span className={baseClasses}>
          Slack <span className={targetClasses}>{target}</span>
        </span>
      );
    case `ntfy`:
      return (
        <span className={baseClasses}>
          Notify <span className={targetClasses}>{target}</span> via ntfy
        </span>
      );
    case `push`:
      return <span className={baseClasses}>Push</span>;
  }
}

function methodDeleteDescription(notificationCount: number): string {
  if (notificationCount === 0) {
    return `This method will no longer be available for new notifications.`;
  }

  return `This will also delete ${notificationCount} ${notificationCount === 1 ? `notification` : `notifications`} that use this method.`;
}
