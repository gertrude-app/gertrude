import { Card, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { SuspensionRequest } from '#/components/types';
import RequestReasonBubble from './RequestReasonBubble';
import RightColumnCard from './RightColumnCard';

interface Props {
  suspensionRequests: SuspensionRequest[];
  viewAllHref: string;
}

const SuspensionRequestsPreviewCard: React.FC<Props> = ({
  suspensionRequests,
  viewAllHref,
}) => (
  <RightColumnCard
    title="Suspension Requests"
    links={[
      {
        text: `View all`,
        href: viewAllHref,
        icon: ArrowRightIcon,
        iconPosition: `right`,
        variant: `ghost`,
      },
    ]}
  >
    <Card padding={3}>
      <VStack>
        {suspensionRequests.slice(0, 3).map((request) => (
          <VStack
            as="a"
            key={request.id}
            href={viewAllHref}
            gap={1.5}
            className="border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer"
          >
            <VStack>
              <Text variant="bodyStrong">{request.personName}</Text>
              <Text variant="captionSubtle">{request.duration}</Text>
            </VStack>
            {request.reason && (
              <RequestReasonBubble>{request.reason}</RequestReasonBubble>
            )}
          </VStack>
        ))}
      </VStack>
    </Card>
  </RightColumnCard>
);

export default SuspensionRequestsPreviewCard;
