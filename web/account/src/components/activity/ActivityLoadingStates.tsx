import { Card, HStack, Skeleton, VStack } from '@gertrude/ui';
import React from 'react';
import CardContainer from '#/components/layout/CardContainer';

const ActivityOverviewLoadingState: React.FC = () => (
  <CardContainer className="flex flex-col gap-4">
    <span role="status" className="sr-only">
      Loading activity summaries
    </span>
    {[0, 1, 2].map((index) => (
      <Card key={index} padding={3}>
        <VStack gap={4}>
          <Skeleton className="h-3.5 w-24" />
          <HStack align="end" gap={2}>
            <Skeleton className="h-7 w-16" />
            <Skeleton className="mb-0.5 h-4 w-28" />
          </HStack>
          <Skeleton radius="full" className="h-2 w-full" />
        </VStack>
      </Card>
    ))}
  </CardContainer>
);

interface ActivityFeedLoadingStateProps {
  showPersonHeading?: boolean;
}

const ActivityFeedLoadingState: React.FC<ActivityFeedLoadingStateProps> = ({
  showPersonHeading = true,
}) => (
  <VStack gap={3}>
    <span role="status" className="sr-only">
      Loading activity
    </span>
    {showPersonHeading && <Skeleton className="h-5 w-36" />}
    <CardContainer className="flex flex-col gap-6">
      <Card padding={3}>
        <VStack gap={3}>
          <Skeleton radius="large" className="h-48 w-full @2xl/main:h-64" />
          <HStack justify="between" gap={4}>
            <Skeleton className="h-4 w-32" />
            <Skeleton radius="medium" className="h-7 w-20" />
          </HStack>
        </VStack>
      </Card>
      <Card padding={3}>
        <VStack gap={3}>
          <Skeleton radius="large" className="h-24 w-full" />
          <HStack justify="between" gap={4}>
            <Skeleton className="h-4 w-40" />
            <Skeleton radius="medium" className="h-7 w-20" />
          </HStack>
        </VStack>
      </Card>
    </CardContainer>
  </VStack>
);

export { ActivityFeedLoadingState, ActivityOverviewLoadingState };
