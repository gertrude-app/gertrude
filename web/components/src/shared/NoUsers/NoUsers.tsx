import React from 'react';
import Button from '../Button';

const NoUsers: React.FC = () => (
  <div className="flex flex-col justify-center items-center p-10 bg-gray-100 rounded-2xl shadow-inner">
    <i className="fa fa-users text-6xl text-gray-300" />
    <h2 className="text-xl font-bold mt-3 mb-2">No users yet</h2>
    <p className="text-gray-500">
      Get started by adding your first user and connecting their device(s)
    </p>
    <Button
      color="primary-violet"
      type="button"
      onClick={() => {}}
      className="mt-6"
      small
    >
      <i className="fa fa-plus mr-4" />
      Add user
    </Button>
  </div>
);

export default NoUsers;
