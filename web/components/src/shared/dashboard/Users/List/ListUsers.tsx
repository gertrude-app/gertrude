import React from 'react';
import Button from '../../../Button';
import PageHeading from '../../PageHeading';
import UserCard from './Card';
import { SubcomponentsOmit } from '../../../types';
import ConnectModal from '../ConnectModal';
import EmptyState from '../../EmptyState';
import { useNavigate } from 'react-router-dom';

type Props = {
  users: SubcomponentsOmit<typeof UserCard, 'addDevice'>;
  addDeviceRequest?: RequestState<number>;
  startAddDevice(userId: UUID): unknown;
  dismissAddDevice(): unknown;
};

const Users: React.FC<Props> = ({
  users,
  addDeviceRequest,
  startAddDevice,
  dismissAddDevice,
}) => {
  const navigate = useNavigate();
  return (
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
              color="primary-violet"
              className="self-center mb-16"
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
              onButtonClick={() => navigate(`/users/new`)}
            />
          </div>
        )}
      </div>
    </div>
  );
};

export default Users;
