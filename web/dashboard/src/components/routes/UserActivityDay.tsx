import React from 'react';
import { useParams } from 'react-router-dom';

const UserActivityDay: React.FC = () => {
  const { userId, date } = useParams<{ userId: string; date: string }>();
  return (
    <h1>
      User <code>{userId}</code> activity on day <code>{date}</code>
    </h1>
  );
};

export default UserActivityDay;
