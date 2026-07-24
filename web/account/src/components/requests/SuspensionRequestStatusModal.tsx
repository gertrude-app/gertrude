import { Button, LoadingDots, Modal, Text, VStack } from '@gertrude/ui';
import React from 'react';

interface Props {
  title: string;
  description: string;
  loading?: boolean;
  onClose: () => void;
  onRetry?: () => void;
}

const SuspensionRequestStatusModal: React.FC<Props> = ({
  title,
  description,
  loading,
  onClose,
  onRetry,
}) => (
  <Modal
    open
    onOpenChange={(open) => {
      if (!open) onClose();
    }}
    title={title}
    description={description}
    size="small"
    footer={
      !loading && (
        <>
          <Button type="button" onClick={onClose} variant="ghost">
            Close
          </Button>
          {onRetry && (
            <Button type="button" onClick={onRetry} variant="primary">
              Try again
            </Button>
          )}
        </>
      )
    }
  >
    {loading && (
      <VStack align="center" gap={3} className="py-5">
        <LoadingDots />
        <Text variant="bodySubtle">Loading suspension request…</Text>
      </VStack>
    )}
  </Modal>
);

export default SuspensionRequestStatusModal;
