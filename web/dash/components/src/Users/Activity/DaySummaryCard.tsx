import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';
import { formatDate } from '@dash/datetime';
import { env } from '@shared/components';
import PillBadge from '../../PillBadge';

type Props = {
  date: Date;
  numItems: number;
  numCompleted: number;
  index: number;
  numDays: number;
};

const DaySummaryCard: React.FC<Props> = ({
  date,
  numCompleted,
  numItems,
  index,
  numDays,
}) => {
  const [completed, setCompleted] = useState(env.isScreenshotTest() ? numCompleted : 0);
  useEffect(() => {
    setTimeout(() => setCompleted(numCompleted), 50);
  }, [numCompleted]);

  return (
    <div className="flex items-stretch">
      <div className="space-x-4 justify-center items-center px-8 hidden lg:flex">
        <div className="flex flex-col items-center self-stretch">
          <div
            className={cx(
              `border border-dashed border-slate-200 flex-grow`,
              index === 0 && `border-none`,
            )}
          />
          <div
            className={cx(
              `w-7 h-7 border-2 rounded-full flex justify-center items-center`,
              numCompleted === 0 ? `border-slate-200` : `border-violet-500`,
              numCompleted === numItems && `bg-violet-500`,
            )}
          >
            <i
              className={cx(
                `fa fa-check`,
                numCompleted === numItems ? `text-white` : `text-slate-50`,
              )}
            />
          </div>
          <div
            className={cx(
              `border border-dashed border-slate-200 flex-grow`,
              index === numDays - 1 && `border-none`,
            )}
          />
        </div>
      </div>
      <Link
        to={formatDate(date, `url`)}
        className={`block p-6 rounded-xl shadow-md border-[0.5px] border-slate-200 bg-white hover:shadow-lg transition cursor-pointer duration-100 flex-grow my-4`}
      >
        <div className="flex items-center space-x-2 mb-4">
          <h2 className="text-slate-700 grow text-lg font-bold relative">
            <span className="sm:hidden">{formatDate(date, `short`)}</span>
            <span className="hidden sm:inline">{formatDate(date, `medium`)}</span>
            {numCompleted === numItems && (
              <PillBadge type="green" small className="absolute right-0 top-0">
                <i className="fa fa-check mr-1" /> Completed
              </PillBadge>
            )}
          </h2>
        </div>
        <div className="h-4 shadow-inner bg-slate-200 rounded-full">
          <div
            className={`h-4 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full [transition-property:width] duration-200 ease-in-out`}
            style={{ width: `${(completed / numItems) * 100}%` }}
          />
        </div>
        <p className="mt-2 text-slate-600">
          <span className="text-lg font-bold">{numCompleted}</span> out of{` `}
          <span className="text-lg font-bold">{numItems}</span> items reviewed
        </p>
      </Link>
    </div>
  );
};

export default DaySummaryCard;
