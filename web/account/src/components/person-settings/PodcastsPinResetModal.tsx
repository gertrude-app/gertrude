import { Button, Modal, Text, VStack } from '@gertrude/ui';
import React from 'react';

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  deviceName: string;
  code: number | null;
};

const PodcastsPinResetModal: React.FC<Props> = ({
  open,
  onOpenChange,
  deviceName,
  code,
}) => (
  <Modal
    open={open}
    onOpenChange={onOpenChange}
    title="Reset Gertrude Podcasts PIN"
    size="small"
    footer={
      <Button type="button" variant="primary" onClick={() => onOpenChange(false)}>
        Done
      </Button>
    }
  >
    <VStack gap={4}>
      <Text variant="body">
        On the {deviceName}, open{` `}
        <strong>Gertrude Podcasts → Settings → Forgot PIN</strong>, then enter this code:
      </Text>
      <div className="rounded-xl border border-stone-200 bg-stone-50 py-4 text-center">
        <span className="font-mono text-3xl font-semibold tracking-[0.3em] text-stone-900">
          {code ?? `------`}
        </span>
      </div>
      <Text variant="bodyMuted">This code expires in one hour.</Text>
    </VStack>
  </Modal>
);

export default PodcastsPinResetModal;
