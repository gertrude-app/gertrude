import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import { typesafe } from '@shared/ts-utils';
import type { ActivityFeedItem } from './UserActivityFeed';
import { UndoMainPadding } from '../../Chrome/Chrome';
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
    <UndoMainPadding>
      <FeedHeader date={date} numItems={items.length} numDeleted={numDeleted} />
      {items.length > 0 ? (
        <ReviewDayWrapper>
          {typesafe.objectEntries(activity).map(([userName, items]) => (
            <div key={userName} className="flex flex-col justify-center space-y-4">
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
                  >
                    <i className="fa-solid fa-thumbs-up mr-2" />
                    Approve all {posessive(userName)} activity
                  </Button>
                </div>
              )}
            </div>
          ))}
          <hr className="h-[3px] bg-gradient-to-l from-indigo-500 to-fuchsia-500 opacity-20" />
          <Button
            className="ScrollTop self-center"
            type="button"
            onClick={() => {
              deleteItems(items.map((item) => item.id));
              setTimeout(() => navigate(`..`, { replace: true }), 100);
            }}
            color="primary"
          >
            <i className="fa-solid fa-thumbs-up mr-2" />
            Approve all user activity
          </Button>
        </ReviewDayWrapper>
      ) : (
        <FeedCaughtUp />
      )}
    </UndoMainPadding>
  );
};

export default CombinedUsersActivityFeed;
