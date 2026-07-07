import { Button, ConfirmationDialog, HStack, Text } from '@gertrude/ui';
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
  <HStack className="rounded-xl border border-stone-200 bg-white p-1.5 pl-3 shadow shadow-stone-300/30">
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
  </HStack>
);

export default NotificationMethodChip;

function methodLabel(method: NotificationMethod): React.ReactNode {
  const baseClasses = `ml-2.5 text-base text-stone-600`;
  const targetClasses = `rounded border-[0.5px] border-stone-300 bg-stone-100 px-1 py-0.25 font-medium text-stone-900`;
  const target = notificationMethodTarget(method);

  switch (method.type) {
    case `email`:
      return (
        <Text variant="body" className={baseClasses}>
          Email <span className={targetClasses}>{target}</span>
        </Text>
      );
    case `text`:
      return (
        <Text variant="body" className={baseClasses}>
          Text <span className={targetClasses}>{target}</span>
        </Text>
      );
    case `slack`:
      return (
        <Text variant="body" className={baseClasses}>
          Slack <span className={targetClasses}>{target}</span>
        </Text>
      );
    case `ntfy`:
      return (
        <Text variant="body" className={baseClasses}>
          Notify <span className={targetClasses}>{target}</span> via ntfy
        </Text>
      );
    case `push`:
      return (
        <Text variant="body" className={baseClasses}>
          Push
        </Text>
      );
  }
}

function methodDeleteDescription(notificationCount: number): string {
  if (notificationCount === 0) {
    return `This method will no longer be available for new notifications.`;
  }

  return `This will also delete ${notificationCount} ${notificationCount === 1 ? `notification` : `notifications`} that use this method.`;
}
