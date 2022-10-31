import React from 'react';
import { ConfirmableEntityAction } from '../../../types';
import ConfirmDestructiveAction from '../ConfirmDestructiveAction';

type Props = {
  type: string;
  action: ConfirmableEntityAction<unknown>;
};

export const ConfirmDeleteEntity: React.FC<Props> = ({ action, type }) => {
  return (
    <ConfirmDestructiveAction
      title={`Delete ${type}?`}
      openWhenPresent={action.id}
      onDismiss={action.cancel}
      onConfirm={action.confirm}
    >
      Are you sure you want to delete this {type}? There is no undo.
    </ConfirmDestructiveAction>
  );
};

export default ConfirmDeleteEntity;
