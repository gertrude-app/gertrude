import { Card, Text, VStack } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import { ArrowRightIcon, InboxIcon } from 'lucide-react';
import React from 'react';
import type { SuspensionRequest } from '#/components/types';
import RightColumnCard from './RightColumnCard';
import MessageBubble from '#/components/MessageBubble';

interface Props {
  suspensionRequests: SuspensionRequest[];
  onRefresh: () => void;
  refreshing?: boolean;
  viewAllHref?: string;
  responseHrefForRequest: (id: string) => string;
}

interface RequestPreviewProps {
  request: SuspensionRequest;
  href: string;
}

const RequestPreview: React.FC<RequestPreviewProps> = ({ request, href }) => (
  <VStack
    as={Link}
    to={href}
    gap={1.5}
    className="cursor-pointer border-b border-stone-200/80 py-3 first:pt-0 last:border-b-0 last:pb-0"
  >
    <VStack>
      <Text variant="bodyStrong">{request.personName}</Text>
      <Text variant="captionSubtle">
        {request.deviceName
          ? `${request.deviceName} · ${request.duration}`
          : request.duration}
      </Text>
    </VStack>
    {request.reason && <MessageBubble>{request.reason}</MessageBubble>}
  </VStack>
);

const SuspensionRequestsPreviewCard: React.FC<Props> = ({
  suspensionRequests,
  onRefresh,
  refreshing,
  viewAllHref,
  responseHrefForRequest,
}) => {
  if (suspensionRequests.length === 0) {
    return (
      <RightColumnCard
        variant="empty"
        icon={InboxIcon}
        text="No pending suspension requests"
        onRefresh={onRefresh}
        refreshing={refreshing}
      />
    );
  }

  return (
    <RightColumnCard
      title="Suspension Requests"
      links={
        viewAllHref
          ? [
              {
                text: `View all`,
                href: viewAllHref,
                icon: ArrowRightIcon,
                iconPosition: `right`,
                variant: `ghost`,
              },
            ]
          : undefined
      }
    >
      <Card padding={3}>
        <VStack>
          {suspensionRequests.slice(0, 3).map((request) => (
            <RequestPreview
              key={request.id}
              request={request}
              href={responseHrefForRequest(request.id)}
            />
          ))}
        </VStack>
      </Card>
    </RightColumnCard>
  );
};

export default SuspensionRequestsPreviewCard;
