import { Button, ConfirmationDialog } from '@gertrude/ui';
import cx from 'clsx';
import { PencilIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Notification, NotificationMethod, NotificationTrigger } from '#/lib/mock';
import {
  notificationMethodIcon,
  notificationMethodTarget,
  notificationMethodTypeLabel,
} from './notificationMethodUtils';
import { notificationTriggerText } from './notificationTriggerUtils';

type Props = {
  notification: Notification;
  onEdit: () => void;
  onDelete: () => void;
};

const NotificationCard: React.FC<Props> = ({ notification, onEdit, onDelete }) => (
  <div className="flex flex-col overflow-hidden rounded-xl border border-stone-200 bg-white shadow shadow-stone-300/30">
    <div className="flex-grow p-4">
      <NotificationSummary
        method={notification.method}
        trigger={notification.trigger}
        className="text-[15px] leading-6 text-stone-800"
      />
    </div>
    <div className="flex flex-col gap-3 border-t border-stone-200 bg-stone-50/80 px-3 py-2 xs:flex-row xs:items-center xs:justify-between">
      <div className="hidden h-8 w-8 shrink-0 items-center justify-center xs:flex">
        {notificationMethodIcon(notification.method)}
      </div>
      <div className="flex flex-col gap-2 xs:flex-row xs:justify-end">
        <Button
          type="button"
          onClick={onEdit}
          size="small"
          variant="default"
          icon={PencilIcon}
        >
          Edit
        </Button>
        <ConfirmationDialog
          confirmationQuestion="Delete notification?"
          description="Gertrude will stop sending this custom notification."
          trigger={
            <Button
              type="button"
              onClick={() => {}}
              size="small"
              variant="destructive"
              icon={TrashIcon}
            >
              Delete
            </Button>
          }
          actions={[
            { text: `Cancel` },
            {
              text: `Delete notification`,
              icon: TrashIcon,
              variant: `destructive`,
              onClick: onDelete,
            },
          ]}
        />
      </div>
    </div>
  </div>
);

export default NotificationCard;

const NotificationSummary: React.FC<{
  method: NotificationMethod;
  trigger: NotificationTrigger;
  className?: string;
}> = ({ method, trigger, className }) => {
  const target = notificationMethodTarget(method);

  return (
    <h3 className={cx(`font-medium`, className)}>
      {notificationMethodTypeLabel(method)}
      {target && (
        <>
          {` `}
          <span className="font-semibold">{target}</span>
        </>
      )}
      {` `}
      for {notificationTriggerText(trigger)}
    </h3>
  );
};
