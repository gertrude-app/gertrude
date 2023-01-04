import React from 'react';
import type { IconType } from '../GradientIcon';
import ApiErrorMessage from '../ApiErrorMessage';
import Modal from './Modal';

interface Props {
  title?: string;
  secondaryButton?:
    | 'contactSupport'
    | null
    | React.ComponentProps<typeof Modal>['secondaryButton'];
  error?: PqlError;
  nonActionableMessage?: string | React.ReactNode;
  entity?: string;
  onDismiss?(): unknown;
  primaryButton?: React.ComponentProps<typeof Modal>['primaryButton'];
  icon?: IconType;
}

const Error: React.FC<Props> = ({
  title,
  secondaryButton = `contactSupport`,
  nonActionableMessage,
  error,
  entity,
  primaryButton,
  onDismiss,
  icon = `exclamation-triangle`,
}) => {
  return (
    <Modal
      type="error"
      title={title ?? (error?.type === `not_found` ? `Not found` : `Error`)}
      icon={icon}
      onDismiss={onDismiss}
      primaryButton={primaryButton ?? (() => (window.location.href = `/`))}
      secondaryButton={
        secondaryButton === `contactSupport`
          ? {
              label: `Contact support`,
              action: () => (window.location.href = `https://gertrude.app/contact`),
            }
          : secondaryButton === null
          ? undefined
          : secondaryButton
      }
    >
      <div className="py-2">
        {error?.type === `non_actionable` && nonActionableMessage !== undefined ? (
          nonActionableMessage
        ) : (
          <ApiErrorMessage error={error} entity={entity} wrapped={false} />
        )}
      </div>
    </Modal>
  );
};

export default Error;
