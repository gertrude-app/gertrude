import React, { useEffect } from 'react';
import { ApiErrorMessage, Loading, UserActivityOverview } from '@dash/components';
import { typesafe } from '@shared/ts-utils';
import { formatDate } from '@shared/datetime';
import { useDispatch, useSelector } from '../../redux/hooks';
import { fetchUsersActivityOverviews } from '../../redux/slice-users';

const AllUsersActivityOverviewRoute: React.FC = () => {
  const dispatch = useDispatch();
  const { request, overviews } = useSelector((state) => ({
    request: state.users.fetchAllActivityOverviews,
    overviews: state.users.activityOverviews,
  }));

  useEffect(() => {
    if (!request?.state || request?.state === `idle`) {
      dispatch(fetchUsersActivityOverviews({}));
    }
  }, [dispatch, request?.state]);

  if (!request || request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  const daysMap = new Map<
    string,
    { date: Date; numItems: number; numCompleted: number }
  >();

  for (const req of typesafe.objectValues(overviews)) {
    if (req.state !== `succeeded`) {
      continue;
    }
    for (const day of req.payload.days) {
      const dayKey = formatDate(new Date(day.date), `url`);

      const existing = daysMap.get(dayKey);
      if (!existing) {
        daysMap.set(dayKey, {
          date: new Date(day.date),
          numItems: day.totalItems,
          numCompleted: day.numApproved,
        });
      } else {
        existing.numItems += day.totalItems;
        existing.numCompleted += day.numApproved;
      }
    }
  }

  return <UserActivityOverview days={[...daysMap.values()]} />;
};

export default AllUsersActivityOverviewRoute;
