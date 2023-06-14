import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import { typesafe } from '@shared/ts-utils';
import type { ActivityFeedItem } from './UserActivityFeed';
import { FeedCaughtUp } from './UserActivityFeed';
import { deleteableChunks } from './UserActivityFeed';
import FeedHeader from './FeedHeader';
import ReviewDayWrapper from './ReviewDayWrapper';
import UserActivityHeader from './UserActivityHeader';

type UserName = string;

interface Props {
  date: Date;
  activity: Record<UserName, ActivityFeedItem[]>;
  numDeleted: number;
  deleteItems(ids: UUID[]): unknown;
  chunkSize?: number;
}

const CombinedUsersActivityFeed: React.FC<Props> = ({
  date,
  activity,
  numDeleted,
  deleteItems,
  chunkSize = 100,
}) => {
  const navigate = useNavigate();

  const items = typesafe.objectValues(activity).flat();

  return (
    <div className="-my-6 -mx-4 sm:-mx-6 md:my-0 md:mx-0">
      <FeedHeader date={date} numItems={items.length} numDeleted={numDeleted} />
      {items.length > 0 ? (
        <ReviewDayWrapper>
          {typesafe.objectEntries(activity).map(([userName, items]) => (
            <div
              key={userName}
              className="flex flex-col justify-center space-y-4 md:border md:border-slate-200 md:rounded-3xl md:pt-6 lg:pt-8 md:px-4 lg:px-8 md:pb-0 md:bg-white/50"
            >
              <UserActivityHeader>{userName}</UserActivityHeader>
              {deleteableChunks(items, chunkSize, deleteItems)}
              {typesafe.objectValues(activity).length > 1 && (
                <div className="flex justify-center pb-8">
                  <Button
                    type="button"
                    onClick={() => {
                      deleteItems(items.map((item) => item.id));
                    }}
                    color="secondary"
                    className="mt-4"
                  >
                    <i className="fa-solid fa-thumbs-up mr-2" />
                    Approve all {posessive(userName)} activity
                  </Button>
                </div>
              )}
            </div>
          ))}
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
            Approve all user activity
          </Button>
        </ReviewDayWrapper>
      ) : (
        <FeedCaughtUp />
      )}
    </div>
  );
};

export default CombinedUsersActivityFeed;
