import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@shared/components';
import { UndoMainPadding } from '../../Chrome/Chrome';
import EmptyState from '../../EmptyState';
import FeedHeader from './FeedHeader';
import ReviewDayWrapper from './ReviewDayWrapper';
import DeletableActivityChunks from './DeletableActivityChunks';

interface Screenshot {
  type: 'Screenshot';
  width: number;
  height: number;
  url: string;
  duringSuspension: boolean;
}

interface KeystrokeLine {
  type: 'KeystrokeLine';
  appName: string;
  line: string;
  duringSuspension: boolean;
}

export type ActivityFeedItem = (Screenshot | KeystrokeLine) & {
  id: UUID;
  ids: UUID[];
  date: string;
  deleted?: boolean;
};

interface Props {
  date: Date;
  items: ActivityFeedItem[];
  numDeleted: number;
  deleteItems(ids: UUID[]): unknown;
  chunkSize?: number;
  highlightSuspensionActivity: boolean;
}

const UserActivityFeed: React.FC<Props> = ({
  date,
  items,
  numDeleted,
  deleteItems,
  chunkSize = 100,
  highlightSuspensionActivity,
}) => {
  const navigate = useNavigate();
  return (
    <UndoMainPadding className="px-0 md:px-8 lg:px-10 py-5 md:py-10 pt-0 md:pt-4 pb-16 flex flex-col bg-slate-100 md:bg-slate-50">
      <FeedHeader date={date} numItems={items.length} numDeleted={numDeleted} />
      {items.length > 0 ? (
        <ReviewDayWrapper>
          <DeletableActivityChunks
            items={items}
            chunkSize={chunkSize}
            deleteItems={deleteItems}
            highlightSuspensionActivity={highlightSuspensionActivity}
          />
          <Button
            className="ScrollTop self-center"
            type="button"
            onClick={() => {
              deleteItems(items.map((item) => item.id));
              setTimeout(() => navigate(`..`, { replace: true }), 100);
            }}
            color="primary"
            size="large"
          >
            <i className="fa-solid fa-thumbs-up mr-2" />
            Approve all
          </Button>
        </ReviewDayWrapper>
      ) : (
        <FeedCaughtUp />
      )}
    </UndoMainPadding>
  );
};

export default UserActivityFeed;

export const FeedCaughtUp: React.FC = () => (
  <EmptyState
    heading="All caught up!"
    secondaryText="Nothing left to review for this day."
    icon="image"
    buttonText="Back to activity"
    buttonIcon="arrow-left"
    action="../"
    className="max-w-7xl"
  />
);
