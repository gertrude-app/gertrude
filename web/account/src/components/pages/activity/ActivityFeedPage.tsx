import { PageHeading } from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
import React from 'react';
import type { ActivityItem } from '#/lib/activity';
import ActivityFeed from '#/components/activity/ActivityFeed';
import DashboardPage from '#/components/layout/DashboardPage';

interface Props {
  date: Date;
  items: ActivityItem[];
  personName?: string;
  showPersonHeading?: boolean;
  breadcrumbs: Array<{ text: string; href: string }>;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
  onDeletePersonActivity?: (personId: string) => void;
}

const ActivityFeedPage: React.FC<Props> = ({
  date,
  items,
  personName,
  showPersonHeading,
  breadcrumbs,
  onToggleFlag,
  onDelete,
  onDeletePersonActivity,
}) => (
  <DashboardPage
    heading={<PageHeading title={formatDate(date, `long`)} breadcrumbs={breadcrumbs} />}
  >
    <ActivityFeed
      items={items}
      personName={personName}
      showPersonHeading={showPersonHeading}
      onToggleFlag={onToggleFlag}
      onDelete={onDelete}
      onDeletePersonActivity={onDeletePersonActivity}
    />
  </DashboardPage>
);

export default ActivityFeedPage;
