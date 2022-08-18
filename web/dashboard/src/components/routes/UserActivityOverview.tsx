import React from 'react';
import { useParams } from 'react-router-dom';

const UserActivityOverview: React.FC = () => {
  const { userId } = useParams<{ userId: string }>();
  return (
    <h1>
      User <code>{userId}</code> Activity Overview
    </h1>
  );
};

export default UserActivityOverview;
