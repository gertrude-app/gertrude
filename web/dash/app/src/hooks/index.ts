import { useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import type { QueryResult } from './query';
import type {
  GetIdentifiedApps,
  GetUnlockRequest,
  KeychainSummary,
  User,
} from '@dash/types';
import type { MutableRefObject } from 'react';
import Current from '../environment';
import { useAuth } from './auth';
import { Key } from './key';
import { useQuery } from './query';

export { useFireAndForget, useOptimism } from './query';
export { useConfirmableDelete, useDeleteEntity, useMutation } from './mutation';
export { Key, useAuth, useQuery };
export { useZip } from './zip';
export { default as useWindowWidth } from './window-width';
export { default as useObservedReducer } from './observed-reducer';

export function useSelectableKeychains(): QueryResult<{
  own: KeychainSummary[];
  public: KeychainSummary[];
}> {
  return useQuery(Key.selectableKeychains, Current.api.getSelectableKeychains);
}

export function useApps(): QueryResult<GetIdentifiedApps.Output> {
  return useQuery(Key.apps, Current.api.getIdentifiedApps);
}

export function useLoginRedirect(): string | null {
  const [searchParams] = useSearchParams();
  const encodedPath = searchParams.get(`redirect`);
  if (encodedPath) {
    return decodeURIComponent(encodedPath);
  }
  return null;
}

export function useUser(id: UUID): QueryResult<User> {
  return useQuery(Key.user(id), () => Current.api.getUser(id));
}

export function useUnlockRequest(id: UUID): QueryResult<GetUnlockRequest.Output> {
  return useQuery(Key.unlockRequest(id), () => Current.api.getUnlockRequest(id));
}

export function useTimeout(
  callback: () => unknown,
  delay: number,
  enabled?: boolean,
): MutableRefObject<number | null> {
  const timeoutRef = useRef<number | null>(null);
  const savedCallback = useRef(callback);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    if (enabled === false) return () => {};
    const tick: () => unknown = () => savedCallback.current();
    if (typeof delay === `number`) {
      timeoutRef.current = window.setTimeout(tick, delay);
      return () => window.clearTimeout(timeoutRef.current ?? undefined);
    } else {
      return () => {};
    }
  }, [delay, enabled]);

  return timeoutRef;
}
