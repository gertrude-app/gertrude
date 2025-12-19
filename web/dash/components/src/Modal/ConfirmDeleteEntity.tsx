import React from 'react';
import type { ConfirmableEntityAction } from '@dash/types';
import ConfirmDestructiveAction from './ConfirmDestructiveAction';

type Props = {
  type: string;
  action: ConfirmableEntityAction<unknown>;
  text?: string;
};

export const ConfirmDeleteEntity: React.FC<Props> = ({ action, type, text }) => (
  <ConfirmDestructiveAction
    title={`Delete ${type}?`}
    openWhenPresent={action.id}
    onDismiss={action.cancel}
    onConfirm={action.confirm}
  >
    {text ?? `Are you sure you want to delete this ${type}? There is no undo.`}
  </ConfirmDestructiveAction>
);

export default ConfirmDeleteEntity;
