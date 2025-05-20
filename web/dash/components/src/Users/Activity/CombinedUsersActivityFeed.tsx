import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import cx from 'classnames';
import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import type { ActivityFeedItem } from './UserActivityFeed';
import { FeedCaughtUp } from './UserActivityFeed';
import DeletableActivityChunks from './DeletableActivityChunks';
import FeedHeader from './FeedHeader';
import ReviewDayWrapper from './ReviewDayWrapper';
import UserActivityHeader from './UserActivityHeader';

interface Props {
  date: Date;
  activity: Array<{
    userName: string;
    highlightSuspensionActivity: boolean;
    items: ActivityFeedItem[];
  }>;
  numDeleted: number;
  deleteItems(ids: UUID[]): unknown;
  flagItem(id: UUID): unknown;
  chunkSize?: number;
}

const CombinedUsersActivityFeed: React.FC<Props> = ({
  date,
  activity,
  numDeleted,
  flagItem,
  deleteItems,
  chunkSize = 100,
}) => {
  const navigate = useNavigate();
  const [initialSort, setInitialSort] = useState<Record<string, number> | null>(null);
  const items = activity.flatMap((user) => user.items);
  const hasFlagged = items.some((item) => item.flagged);

  activity.sort((a, b) => {
    if (initialSort) {
      return (initialSort[b.userName] || 0) - (initialSort[a.userName] || 0);
    } else {
      return a.items.length > b.items.length ? -1 : 1;
    }
  });

  useEffect(() => {
    if (initialSort) return;
    setInitialSort(
      activity.reduce<Record<string, number>>(
        (acc, { userName, items }) => ({ ...acc, [userName]: items.length }),
        {},
      ),
    );
  }, [activity, initialSort]);

  return (
    <div className="-my-6 -mx-4 sm:-mx-6 md:my-0 md:mx-0">
      <FeedHeader date={date} numItems={items.length} numDeleted={numDeleted} />
      {items.length > 0 ? (
        <ReviewDayWrapper>
          {activity.map(({ userName, highlightSuspensionActivity, items }) => (
            <div
              key={userName}
              className="flex flex-col justify-center space-y-4 md:border md:border-slate-200 md:rounded-3xl md:pt-6 lg:pt-8 md:px-4 lg:px-8 md:pb-0 md:bg-white/50"
              data-test="single-user-sub-feed"
            >
              <UserActivityHeader>{userName}</UserActivityHeader>
              <div className={cx(`flex flex-col gap-4`, items.length === 1 && `pb-2`)}>
                <DeletableActivityChunks
                  items={items}
                  chunkSize={chunkSize}
                  deleteItems={deleteItems}
                  flagItem={flagItem}
                  highlightSuspensionActivity={highlightSuspensionActivity}
                />
                {items.length > 1 && (
                  <div className="flex justify-center pb-8">
                    <Button
                      type="button"
                      onClick={() => deleteItems(items.map((item) => item.id))}
                      color="secondary"
                      className="ScrollTop mt-4"
                      disabled={items.every((item) => item.flagged)}
                    >
                      <i className="fa-solid fa-thumbs-up mr-2" />
                      Delete all {posessive(userName)}
                      {items.some((i) => i.flagged) ? ` unflagged` : ` activity`}
                    </Button>
                  </div>
                )}
              </div>
            </div>
          ))}
          <Button
            className="ScrollTop self-center"
            disabled={items.every((item) => item.flagged)}
            type="button"
            onClick={() => {
              deleteItems(items.map((item) => item.id));
              setTimeout(
                () => navigate(`..`, { replace: true }),
                hasFlagged ? 2000 : 200,
              );
            }}
            color="primary"
            size="large"
          >
            <i className="fa-solid fa-thumbs-up mr-2" />
            Delete {hasFlagged ? `unflagged` : `all`} activity
          </Button>
        </ReviewDayWrapper>
      ) : (
        <FeedCaughtUp />
      )}
    </div>
  );
};

export default CombinedUsersActivityFeed;
