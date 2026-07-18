import { Text, VStack } from '@gertrude/ui';
import React from 'react';
import type { ActivityItem } from '#/lib/activity';
import ActivityPersonSection from '#/components/activity/ActivityPersonSection';
import CardContainer from '#/components/layout/CardContainer';

interface Props {
  items: ActivityItem[];
  personName?: string;
  showPersonHeading?: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
  onDeletePersonActivity?: (personId: string) => void;
}

type ActivityItemGroup = {
  personId: string;
  personName: string;
  items: ActivityItem[];
};

const ActivityFeed: React.FC<Props> = ({
  items,
  personName,
  showPersonHeading = true,
  onToggleFlag,
  onDelete,
  onDeletePersonActivity,
}) => {
  const visibleItems = items.filter((item) => !item.deleted);
  const [firstVisibleItem] = visibleItems;

  if (!firstVisibleItem) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <Text variant="bodyMuted" className="text-center">
          No activity to review.
        </Text>
      </CardContainer>
    );
  }

  const groupsByPersonId = new Map<string, ActivityItemGroup>();

  visibleItems.forEach((item) => {
    const group = groupsByPersonId.get(item.personId);

    if (group) {
      group.items.push(item);
    } else {
      groupsByPersonId.set(item.personId, {
        personId: item.personId,
        personName: item.personName,
        items: [item],
      });
    }
  });

  const itemGroups: ActivityItemGroup[] = personName
    ? [{ personId: firstVisibleItem.personId, personName, items: visibleItems }]
    : Array.from(groupsByPersonId.values());

  return (
    <VStack gap={16}>
      {itemGroups.map((group) => (
        <ActivityPersonSection
          key={group.personId}
          personId={group.personId}
          personName={group.personName}
          items={group.items}
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
