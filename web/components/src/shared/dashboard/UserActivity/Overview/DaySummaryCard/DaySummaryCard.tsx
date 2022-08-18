import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { formatDate } from '../../../../lib/dates';
import PillBadge from '../../../PillBadge';

type Props = {
  date: Date;
  numItems: number;
  numCompleted: number;
};

const DaySummaryCard: React.FC<Props> = ({ date, numCompleted, numItems }) => {
  const [completed, setCompleted] = useState(0);
  useEffect(() => {
    setTimeout(() => setCompleted(numCompleted), 50);
  }, [numCompleted]);

  return (
    <Link
      to={formatDate(date, `url`)}
      className={`block p-6 rounded-xl shadow-lg border bg-white hover:border-violet-400 transition cursor-pointer duration-100`}
    >
      <div className="flex items-center space-x-2 mb-4">
        <i
          className={`fa fa-calendar text-2xl bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent [-webkit-background-clip:text;] w-min`}
        />
        <h2 className="text-gray-700 grow text-lg font-medium relative">
          <span className="sm:hidden">{formatDate(date, `short`)}</span>
          <span className="hidden sm:inline">{formatDate(date, `medium`)}</span>
          {numCompleted === numItems && (
            <PillBadge type="green" className="absolute right-0 top-0">
              <i className="fa fa-check mr-1" /> Completed
            </PillBadge>
          )}
        </h2>
      </div>
      <div className="h-4 shadow-inner bg-gray-200 rounded-full">
        <div
          className={`h-4 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full [transition-property:width] duration-200 ease-in-out`}
          style={{ width: `${(completed / numItems) * 100}%` }}
        />
      </div>
      <p className="mt-2 text-gray-600">
        <span className="text-lg font-bold">{numCompleted}</span> out of{` `}
        <span className="text-lg font-bold">{numItems}</span> items reviewed
      </p>
    </Link>
  );
};

export default DaySummaryCard;
