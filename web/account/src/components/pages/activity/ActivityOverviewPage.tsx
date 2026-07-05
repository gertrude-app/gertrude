import { PageHeading } from '@gertrude/ui';
import React from 'react';
import type { DaySummary } from '#/lib/activity';
import ActivityOverviewList, {
  type DayLinkTarget,
} from '#/components/activity/ActivityOverviewList';
import DashboardPage from '#/components/layout/DashboardPage';

interface Props {
  title: string;
  subtitle?: string;
  days: DaySummary[];
  dayLink: DayLinkTarget;
  emptyText?: string;
  breadcrumbs?: Array<{ text: string; href: string }>;
}

const ActivityOverviewPage: React.FC<Props> = ({
  title,
  subtitle,
  days,
  dayLink,
  emptyText,
  breadcrumbs,
}) => (
  <DashboardPage
    heading={<PageHeading title={title} subtitle={subtitle} breadcrumbs={breadcrumbs} />}
  >
    <ActivityOverviewList days={days} dayLink={dayLink} emptyText={emptyText} />
  </DashboardPage>
);

export default ActivityOverviewPage;
