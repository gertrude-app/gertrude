import React from 'react';
import type { PqlError } from '@dash/types';
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
  onDismiss?(): unknown;
  primaryButton?: React.ComponentProps<typeof Modal>['primaryButton'];
  icon?: IconType;
}

const Error: React.FC<Props> = ({
  title,
  secondaryButton = `contactSupport`,
  error,
  primaryButton,
  onDismiss,
  icon = `exclamation-triangle`,
}) => {
  return (
    <Modal
      type="error"
      title={title ?? (error?.type === `notFound` ? `Not found` : `Error`)}
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
        <ApiErrorMessage error={error} wrapped={false} />
      </div>
    </Modal>
  );
};

export default Error;
