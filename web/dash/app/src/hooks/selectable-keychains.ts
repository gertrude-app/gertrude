import { useEffect } from 'react';
import { Keychain } from '@dash/keys';
import { fetchSelectableKeychains } from '../redux/slice-keychains';
import { useDispatch, useSelector } from '../redux/hooks';

export default function useSelectableKeychains(
  fetch = true,
): RequestState<{ own: Keychain[]; public: Keychain[] }, ApiError> {
  const dispatch = useDispatch();
  const keychains = useSelector(
    (state) => state.keychains.fetchSelectableKeychainsRequest,
  );

  useEffect(() => {
    if (fetch && keychains.state === `idle`) {
      dispatch(fetchSelectableKeychains());
    }
  }, [dispatch, fetch, keychains.state]);

  return keychains;
}
