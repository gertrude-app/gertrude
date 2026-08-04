import { ConfirmationDialog } from '@gertrude/ui';
import { useBlocker } from '@tanstack/react-router';
import React from 'react';

interface Props {
  hasUnsavedChanges: boolean;
  description: string;
}

const UnsavedChangesGuard: React.FC<Props> = ({ hasUnsavedChanges, description }) => {
  const shouldBlockNavigation = React.useCallback(
    () => hasUnsavedChanges,
    [hasUnsavedChanges],
  );
  const blocker = useBlocker({
    shouldBlockFn: shouldBlockNavigation,
    enableBeforeUnload: hasUnsavedChanges,
    disabled: !hasUnsavedChanges,
    withResolver: true,
  });

  return blocker.status === `blocked` ? (
    <ConfirmationDialog
      open
      onOpenChange={(open) => {
        if (!open) {
          blocker.reset();
        }
      }}
      confirmationQuestion="Discard unsaved changes?"
      description={description}
      actions={[
        { text: `Keep editing`, autoClose: false, onClick: blocker.reset },
        {
          text: `Discard and leave`,
          variant: `destructive`,
          autoClose: false,
          onClick: blocker.proceed,
        },
      ]}
    />
  ) : null;
};

export default UnsavedChangesGuard;
