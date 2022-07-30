import React from 'react';
import Button from '../Button';
import PillBadge from '../PillBadge';

type Props = {
  className?: string;
  date: Date;
  numItems: number;
  numCompleted: number;
};

const days = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
const months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const MonitoredDay: React.FC<Props> = ({ className, date, numCompleted, numItems }) => (
  <div className="p-6 rounded-xl shadow-lg border bg-white relative hover:border-violet-400 transition cursor-pointer duration-100">
    <h2 className="text-gray-700 text-lg mb-6 font-medium">{`${days[date.getDay()]} ${
      months[date.getMonth()]
    } ${date.getDate()}, ${date.getFullYear()}`}</h2>
    <div className="h-4 shadow-inner bg-gray-200 rounded-full">
      <div
        className={`h-4 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full`}
        style={{ width: `${(numCompleted / numItems) * 100}%` }}
      />
    </div>
    <p className="mt-2 text-gray-600">
      <span className="text-lg font-bold">{numCompleted}</span> out of{' '}
      <span className="text-lg font-bold">{numItems}</span> items reviewed
    </p>
    {numCompleted === numItems && (
      <PillBadge type="green" className="absolute right-4 top-4">
        <i className="fa fa-check mr-1" /> Completed
      </PillBadge>
    )}
  </div>
);

export default MonitoredDay;
