import { Button, Card, HStack, Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { SuspensionRequest } from '#/components/types';
import RequestReasonBubble from './RequestReasonBubble';

interface Props {
  request: SuspensionRequest;
  responseHref: string;
}

const SuspensionRequestCard: React.FC<Props> = ({ request, responseHref }) => (
  <Card preset="big" padding={4} className="flex flex-col justify-between">
    <VStack>
      <VStack>
        <Text as="h2" variant="heading">
          {request.personName}
        </Text>
        <Text variant="bodySubtle" className="-mt-0.5">
          {request.deviceName
            ? `${request.deviceName} · ${request.duration}`
            : request.duration}
        </Text>
      </VStack>
      {request.reason && (
        <RequestReasonBubble className="mt-2">{request.reason}</RequestReasonBubble>
      )}
    </VStack>
    <HStack justify="end" gap={2} className="mt-4">
      <Button type="link" href={responseHref} size="small">
        Respond…
      </Button>
    </HStack>
  </Card>
);

export default SuspensionRequestCard;
