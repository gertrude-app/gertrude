import React from 'react';
import { Button } from '@shared/components';
import type { Subcomponents, RequestState } from '@dash/types';
import EmptyState from '../EmptyState';
import PageHeading from '../PageHeading';
import ConnectModal from './ConnectDeviceModal';
import UserCard from './UserCard';

type Props = {
  users: Subcomponents<typeof UserCard>;
  addDeviceRequest?: RequestState<{ code: number }>;
  startAddDevice(userId: UUID): unknown;
  dismissAddDevice(): unknown;
};

const Users: React.FC<Props> = ({
  users,
  addDeviceRequest,
  startAddDevice,
  dismissAddDevice,
}) => (
  <div className="flex flex-col">
    <ConnectModal request={addDeviceRequest} dismissAddDevice={dismissAddDevice} />
    <PageHeading icon="users">Users</PageHeading>
    <div className="mt-8 flex flex-col">
      {users.length > 0 ? (
        <>
          <div className="mb-16 grid grid-cols-1 lg+:grid-cols-2 gap-10 lg+:gap-8 xl:gap-10 2xl:grid-cols-3">
            {users.map((user) => (
              <UserCard
                key={user.id}
                addDevice={() => startAddDevice(user.id)}
                {...user}
              />
            ))}
          </div>
          <Button
            type="link"
            to="/users/new"
            color="primary"
            className="self-center mb-16"
            size="large"
          >
            <i className="fa fa-plus mr-4" />
            Add a user
          </Button>
        </>
      ) : (
        <div>
          <EmptyState
            heading={`No users`}
            secondaryText={`Get started by creating a protected user`}
            icon={`user`}
            buttonText={`Add a user`}
            action={`/users/new`}
          />
        </div>
      )}
    </div>
  </div>
);

export default Users;
