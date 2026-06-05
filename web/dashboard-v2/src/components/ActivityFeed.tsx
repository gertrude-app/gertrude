import React from 'react';
import type { ActivityItem } from '#/lib/mock-data/activity';
import ActivityPersonSection from '#/components/ActivityPersonSection';
import CardContainer from '#/components/CardContainer';
import { groupBy } from '#/lib/utils';

interface Props {
  items: ActivityItem[];
  personName?: string;
  showPersonHeading?: boolean;
}

const ActivityFeed: React.FC<Props> = ({
  items,
  personName,
  showPersonHeading = true,
}) => {
  const visibleItems = items.filter((item) => !item.deleted);

  if (visibleItems.length === 0) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span className="text-center text-sm text-stone-500">No activity to review.</span>
      </CardContainer>
    );
  }

  const itemGroups = personName
    ? [[personName, visibleItems] as const]
    : Array.from(groupBy(visibleItems, (item) => item.personName).entries());

  return (
    <div className="flex flex-col gap-16">
      {itemGroups.map(([groupPersonName, groupItems]) => (
        <ActivityPersonSection
          key={groupPersonName}
          personName={groupPersonName}
          items={groupItems}
          showHeading={personName ? showPersonHeading : true}
        />
      ))}
    </div>
  );
};

export default ActivityFeed;
