import React from 'react';
import Button from '../../../Button';
import PageHeading from '../../PageHeading';
import NoUsers from './NoUsers';
import UserCard, { Props as UserCardProps } from './Card';

type Props = {
  users: Array<UserCardProps & { id: string }>;
};

const Users: React.FC<Props> = ({ users }) => (
  <div className="flex flex-col">
    <PageHeading icon="users">Users</PageHeading>
    <div className="mt-8 flex flex-col">
      {users.length > 0 ? (
        <>
          <div className="mb-16 grid grid-cols-1 lg+:grid-cols-2 gap-10 lg+:gap-8 xl:gap-10 2xl:grid-cols-3">
            {users.map((user) => (
              <UserCard key={user.id} {...user} />
            ))}
          </div>
          <Button
            type="button"
            onClick={() => {}}
            color="primary-violet"
            className="self-center"
          >
            <i className="fa fa-plus mr-4" />
            Add a user
          </Button>
        </>
      ) : (
        <div>
          <NoUsers />
        </div>
      )}
    </div>
  </div>
);

export default Users;
