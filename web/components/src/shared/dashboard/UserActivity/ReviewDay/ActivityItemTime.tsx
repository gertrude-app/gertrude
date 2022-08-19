import React from 'react';

interface Props {
  date: Date;
}

const ActivityItemTime: React.FC<Props> = ({ date }) => (
  <div className="text-violet-900/90 text-xs">
    {date.toLocaleDateString()} - {date.toLocaleTimeString()}
  </div>
);

export default ActivityItemTime;
