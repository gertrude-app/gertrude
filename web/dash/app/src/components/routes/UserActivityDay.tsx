import React, { useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { dateFromUrl } from '@dash/datetime';
import { ApiErrorMessage, Loading, UserActivityReviewDay } from '@dash/components';
import { useDispatch, useSelector } from '../../redux/hooks';
import * as typesafe from '../../lib/typesafe';
import {
  deleteActivityItems,
  fetchActivityDay,
  activityDayKey,
} from '../../redux/slice-users';

const UserActivityDay: React.FC = () => {
  const { userId = ``, date = `` } = useParams<{ userId: string; date: string }>();
  const day = dateFromUrl(date);
  const key = activityDayKey(userId, day);
  const dispatch = useDispatch();
  const request = useSelector((state) => state.users.activityDays[key]);
  const reqState = request?.state;

  useEffect(() => {
    if (!reqState || reqState === `idle`) {
      dispatch(fetchActivityDay({ userId, day: dateFromUrl(date) }));
    }
  }, [dispatch, userId, date, reqState]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  return (
    <UserActivityReviewDay
      date={day}
      numDeleted={request.payload.numDeleted}
      deleteItems={(itemRootIds) =>
        dispatch(deleteActivityItems({ userId, date: day, itemRootIds }))
      }
      items={typesafe.objectValues(request.payload.items).filter((item) => !item.deleted)}
    />
  );
};

export default UserActivityDay;
