import React from 'react';
import cx from 'classnames';
import { newestFirst } from '@dash/utils';
import { posessive } from '@shared/string';
import type { Subcomponents } from '@dash/types';
import UnlockRequestCard from '../UnlockRequestCard';
import PageHeading from '../PageHeading';
import PartyMessage from '../PartyMessage';

type Props = {
  singleUser?: boolean;
  requests: Subcomponents<typeof UnlockRequestCard>;
};

const ListUnlockRequests: React.FC<Props> = ({ requests, singleUser }) => (
  <div className="flex flex-col space-y-6">
    <PageHeading icon="unlock">
      {requests.length > 0 && singleUser
        ? `${posessive(requests[0]?.userName ?? ``)} unlock requests`
        : `Unlock requests`}
    </PageHeading>
    {requests.length > 0 ? (
      <div className={cx(requests.length > 1 && `grid gap-5 grid-cols-1 lg:grid-cols-2`)}>
        {requests
          .sort((a, b) =>
            a.status === `pending` && b.status !== `pending` ? -1 : newestFirst(a, b),
          )
          .map((request) => (
            <UnlockRequestCard key={request.id} {...request} />
          ))}
      </div>
    ) : (
      <PartyMessage>No unlock requests for this user</PartyMessage>
    )}
  </div>
);

export default ListUnlockRequests;
