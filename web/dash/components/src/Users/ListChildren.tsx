import { Button } from '@shared/components';
import React from 'react';
import type { RequestState, Subcomponents } from '@dash/types';
import EmptyState from '../EmptyState';
import PageHeading from '../PageHeading';
import ChildCard from './ChildCard';
import ConnectModal from './ConnectDeviceModal';

type Props = {
  users: Subcomponents<typeof ChildCard>;
  addDeviceRequest?: RequestState<{ code: number }>;
  startAddDevice(userId: UUID): unknown;
  dismissAddDevice(): unknown;
};

const ListChildren: React.FC<Props> = ({
  users,
  addDeviceRequest,
  startAddDevice,
  dismissAddDevice,
}) => (
  <div className="flex flex-col">
    <ConnectModal request={addDeviceRequest} dismissAddDevice={dismissAddDevice} />
    <PageHeading icon="users">Children</PageHeading>
    <div className="mt-8 flex flex-col">
      {users.length > 0 ? (
        <>
          <div className="mb-16 grid grid-cols-1 xl:grid-cols-2 gap-10 lg+:gap-8 xl:gap-10 2xl:grid-cols-3">
            {users.map((user) => (
              <ChildCard
                key={user.id}
                addDevice={() => startAddDevice(user.id)}
                {...user}
              />
            ))}
          </div>
          <Button
            type="link"
            to="/children/new"
            color="primary"
            className="self-center mb-16"
            size="large"
          >
            <i className="fa fa-plus mr-4" />
            Add a child
          </Button>
        </>
      ) : (
        <div>
          <EmptyState
            heading="No children"
            secondaryText="Get started by adding a child."
            icon="user"
            buttonText="Add a child"
            action="/children/new"
          />
        </div>
      )}
    </div>
  </div>
);

export default ListChildren;
