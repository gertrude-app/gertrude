import React from 'react';
import Modal from './Modal';

interface Props {
  title: string;
  confirmText?: string;
  cancelText?: string;
  openWhenPresent?: unknown;
  onDismiss(): unknown;
  onConfirm(): unknown;
  children?: React.ReactNode;
}

const ConfirmDestructiveAction: React.FC<Props> = ({
  title,
  confirmText = `Delete`,
  cancelText = `Cancel`,
  onConfirm,
  onDismiss,
  openWhenPresent,
  children,
}) => (
  <Modal
    type="destructive"
    title={title}
    primaryButton={{ action: onConfirm, label: confirmText }}
    isOpen={!!openWhenPresent}
    secondaryButton={{ action: onDismiss, label: cancelText }}
    children={children}
  />
);

export default ConfirmDestructiveAction;
