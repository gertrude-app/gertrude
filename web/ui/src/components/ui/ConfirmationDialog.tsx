import React from 'react';
import type { LucideIcon } from 'lucide-react';
import Button from './Button';
import Modal from './Modal';

type ButtonVariant = `primary` | `default` | `ghost` | `destructive`;

export interface ConfirmationDialogAction {
  text: string;
  onClick?: () => void | Promise<void>;
  variant?: ButtonVariant;
  icon?: LucideIcon;
  disabled?: boolean;
  loading?: boolean;
  autoClose?: boolean;
}

export interface ConfirmationDialogProps {
  confirmationQuestion: string;
  actions: ConfirmationDialogAction[];
  description?: React.ReactNode;
  trigger?: React.ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  size?: `small` | `medium` | `large`;
}

const ConfirmationDialog: React.FC<ConfirmationDialogProps> = ({
  confirmationQuestion,
  actions,
  description,
  trigger,
  open,
  onOpenChange,
  size = `small`,
}) => {
  const [internalOpen, setInternalOpen] = React.useState(false);
  const [pendingActionIndex, setPendingActionIndex] = React.useState<number | null>(null);
  const modalOpen = open ?? internalOpen;

  const setOpen = (nextOpen: boolean): void => {
    setInternalOpen(nextOpen);
    onOpenChange?.(nextOpen);
  };

  const runAction = async (
    action: ConfirmationDialogAction,
    index: number,
  ): Promise<void> => {
    setPendingActionIndex(index);

    try {
      await action.onClick?.();

      if (action.autoClose !== false) {
        setOpen(false);
      }
    } finally {
      setPendingActionIndex(null);
    }
  };

  return (
    <Modal
      open={modalOpen}
      onOpenChange={setOpen}
      trigger={trigger}
      title={confirmationQuestion}
      description={description}
      size={size}
      footer={actions.map((action, index) => (
        <Button
          key={`${action.text}-${index}`}
          type="button"
          variant={action.variant ?? `default`}
          icon={action.icon}
          disabled={action.disabled || pendingActionIndex !== null}
          loading={action.loading || pendingActionIndex === index}
          onClick={() => void runAction(action, index)}
        >
          {action.text}
        </Button>
      ))}
    />
  );
};

export default ConfirmationDialog;
