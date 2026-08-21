import { Card, HStack, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { UnlockRequest } from '#/components/types';
import RightColumnCard from './RightColumnCard';
import MessageBubble from '#/components/MessageBubble';

interface Props {
  unlockRequests: UnlockRequest[];
  viewAllHref: string;
}

const UnlockRequestsPreviewCard: React.FC<Props> = ({ unlockRequests, viewAllHref }) => (
  <RightColumnCard
    title="Unlock Requests"
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
        {unlockRequests.slice(0, 3).map((request) => (
          <VStack
            as="a"
            key={request.id}
            href={request.reviewHref ?? viewAllHref}
            className="border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer"
          >
            <Text variant="bodyStrong">{request.personName}</Text>
            <HStack wrap gap={1} className="mt-0.5">
              {request.domains.slice(0, 4).map((domain) => (
                <Text
                  key={domain}
                  variant="captionSubtleStrong"
                  className="bg-stone-50 border border-stone-200 px-1 rounded"
                >
                  {domain}
                </Text>
              ))}
              {request.domains.length > 4 && (
                <Text variant="captionMuted">+ {request.domains.length - 4} more</Text>
              )}
            </HStack>
            {request.reason && (
              <MessageBubble className="mt-3">{request.reason}</MessageBubble>
            )}
          </VStack>
        ))}
      </VStack>
    </Card>
  </RightColumnCard>
);

export default UnlockRequestsPreviewCard;
