import { formatDate } from '@dash/datetime';
import React from 'react';
import { Link } from 'react-router-dom';

interface Props {
  date: Date;
  numItems: number;
  numDeleted: number;
}

const FeedHeader: React.FC<Props> = ({ date, numItems, numDeleted }) => (
  <header className="flex items-center justify-between p-2 pr-6 rounded-b-2xl md:rounded-t-2xl shadow-lg shadow-slate-800/10 bg-white max-w-7xl mb-8 z-20 relative">
    <div className="flex items-center text-md sm:text-l">
      <Link
        to="../"
        className="flex items-center mr-4 sm:mr-8 text-slate-500 hover:bg-violet-50 py-2 px-4 rounded-xl antialiased hover:text-violet-600 transition-colors duration-100 font-medium"
      >
        <i className="fa fa-chevron-left mr-2" aria-hidden /> Back
      </Link>
      <h1 className="font-bold text-slate-800 block xs:hidden">
        {formatDate(date, `m/d/yyyy`)}
      </h1>
      <h1 className="font-bold text-slate-800 hidden xs:block">
        {formatDate(date, `medium`)}
      </h1>
    </div>
    {numItems > 0 && (
      <div className="text-slate-600 self-center flex items-center space-x-0.5 sm:space-x-1">
        <span className="font-bold sm:text-lg">{numDeleted}</span>
        <span className="hidden lg:inline">out of</span>
        <span className="lg:hidden">/</span>
        <span className="font-bold sm:text-lg">{numDeleted + numItems}</span>
        <span className="hidden lg:inline">items reviewed</span>
      </div>
    )}
  </header>
);

export default FeedHeader;
