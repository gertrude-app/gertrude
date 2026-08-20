import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { KeychainDetail, LoadableState } from '#/components/types';
import KeychainDetailPage from '#/components/pages/keychains/KeychainDetailPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const KeychainDetailRoute: React.FC = () => {
  const { keychainId } = Route.useParams();
  const query = useQuery(Key.keychain(keychainId), () =>
    liveClient.getAccountKeychain({ keychainId }),
  );
  const state: LoadableState<KeychainDetail> =
    query.data !== undefined
      ? { status: `success`, data: query.data }
      : query.isError
        ? {
            status: `error`,
            message:
              query.error.userMessage ??
              (query.error.type === `notFound`
                ? `This keychain may have been deleted or belong to another account.`
                : `Check your connection and try again.`),
            onRetry: () => void query.refetch(),
          }
        : { status: `loading` };

  return <KeychainDetailPage state={state} />;
};

export const Route = createFileRoute(`/_app/keychains/$keychainId`)({
  component: KeychainDetailRoute,
});
