import { useSearchParams } from 'react-router-dom';
import type {
  GetIdentifiedApps,
  GetUnlockRequest,
  KeychainSummary,
  User,
} from '@dash/types';
import type { QueryResult } from './query';
import Current from '../environment';
import { useQuery } from './query';
import { Key } from './key';
import { useAuth } from './auth';

export { useFireAndForget, useOptimism } from './query';
export { useMutation, useDeleteEntity, useConfirmableDelete } from './mutation';
export { useQuery, useAuth, Key };
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
