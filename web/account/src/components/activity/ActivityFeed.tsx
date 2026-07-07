import { Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { ActivityItem } from '#/lib/activity';
import ActivityPersonSection from '#/components/activity/ActivityPersonSection';
import CardContainer from '#/components/layout/CardContainer';
import { groupBy } from '#/lib/utils';

interface Props {
  items: ActivityItem[];
  personName?: string;
  showPersonHeading?: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
  onDeletePersonActivity?: (personId: string) => void;
}

const ActivityFeed: React.FC<Props> = ({
  items,
  personName,
  showPersonHeading = true,
  onToggleFlag,
  onDelete,
  onDeletePersonActivity,
}) => {
  const visibleItems = items.filter((item) => !item.deleted);

  if (visibleItems.length === 0) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <Text variant="bodyMuted" className="text-center">
          No activity to review.
        </Text>
      </CardContainer>
    );
  }

  const itemGroups = personName
    ? [[personName, visibleItems] as const]
    : Array.from(groupBy(visibleItems, (item) => item.personName).entries());

  return (
    <VStack gap={16}>
      {itemGroups.map(([groupPersonName, groupItems]) => (
        <ActivityPersonSection
          key={groupPersonName}
          personName={groupPersonName}
          items={groupItems}
          showHeading={personName ? showPersonHeading : true}
          onToggleFlag={onToggleFlag}
          onDelete={onDelete}
          onDeleteAll={onDeletePersonActivity}
        />
      ))}
    </VStack>
  );
};

export default ActivityFeed;
