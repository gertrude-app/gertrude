import React, { useEffect } from 'react';
import { ApiErrorMessage, Loading, ActivitySummaries } from '@dash/components';
import { typesafe } from '@shared/ts-utils';
import { formatDate } from '@shared/datetime';
import { useDispatch, useSelector } from '../../redux/hooks';
import { fetchCombinedUsersActivitySummaries } from '../../redux/slice-users';

const CombinedUsersActivitySummariesRoute: React.FC = () => {
  const dispatch = useDispatch();
  const { request, overviews } = useSelector((state) => ({
    request: state.users.fetchCombinedUsersActivitySummaries,
    overviews: state.users.userActivitySummaries,
  }));

  useEffect(() => {
    if (!request?.state || request?.state === `idle`) {
      dispatch(fetchCombinedUsersActivitySummaries({}));
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

  return <ActivitySummaries days={[...daysMap.values()]} />;
};

export default CombinedUsersActivitySummariesRoute;
