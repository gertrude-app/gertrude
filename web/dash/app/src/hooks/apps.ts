import { useEffect } from 'react';
import type { GetIdentifiedApps, RequestState } from '@dash/types';
import { getIdentifiedApps } from '../redux/slice-apps';
import { useDispatch, useSelector } from '../redux/hooks';

export default function useApps(fetch = true): RequestState<GetIdentifiedApps.Output> {
  const dispatch = useDispatch();
  const apps = useSelector((state) => state.apps.request);

  useEffect(() => {
    if (fetch && apps.state === `idle`) {
      dispatch(getIdentifiedApps());
    }
  }, [dispatch, fetch, apps.state]);

  return apps;
}
