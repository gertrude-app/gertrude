import React from 'react';

interface Props {
  date: Date;
}

const ActivityItemTime: React.FC<Props> = ({ date }) => (
  <div className="text-slate-500 text-sm font-medium">
    {date.toLocaleDateString()} - {date.toLocaleTimeString()}
  </div>
);

export default ActivityItemTime;
