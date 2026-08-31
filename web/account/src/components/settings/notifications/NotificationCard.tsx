import { Button, Card, ConfirmationDialog, Text } from '@gertrude/ui';
import { PencilIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type {
  Notification,
  NotificationMethod,
  NotificationTrigger,
} from '#/components/types';
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
  <Card padding={0} className="flex flex-col overflow-hidden">
    <Card.Body padding={4} className="flex-grow">
      <NotificationSummary method={notification.method} trigger={notification.trigger} />
    </Card.Body>
    <Card.Footer className="flex flex-col gap-3 xs:flex-row xs:items-center xs:justify-between">
      <div className="hidden h-8 w-8 shrink-0 items-center justify-center xs:flex">
        {notificationMethodIcon(notification.method)}
      </div>
      <StackActions onEdit={onEdit} onDelete={onDelete} />
    </Card.Footer>
  </Card>
);

export default NotificationCard;

const StackActions: React.FC<{ onEdit: () => void; onDelete: () => void }> = ({
  onEdit,
  onDelete,
}) => (
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
);

const NotificationSummary: React.FC<{
  method: NotificationMethod;
  trigger: NotificationTrigger;
}> = ({ method, trigger }) => {
  const target = notificationMethodTarget(method);

  return (
    <Text as="h3" variant="bodyLargeStrong">
      {notificationMethodTypeLabel(method)}
      {target && (
        <>
          {` `}
          <strong className="font-semibold">{target}</strong>
        </>
      )}
      {` `}
      for {notificationTriggerText(trigger)}
    </Text>
  );
};
