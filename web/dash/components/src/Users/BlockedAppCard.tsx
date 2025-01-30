import React, { useState } from 'react';
import cx from 'classnames';
import { defaults } from '@dash/types';
import { ChevronDownIcon, ClockIcon, TrashIcon } from '@heroicons/react/24/outline';
import type { RuleSchedule, BlockedApp } from '@dash/types';
import SchedulePicker from '../Keychains/schedule/SchedulePicker';

interface Props {
  app: BlockedApp;
  setSchedule(schedule?: RuleSchedule): void;
  onDelete(): void;
}

const BlockedAppCard: React.FC<Props> = ({ app, setSchedule, onDelete }) => {
  const [showSchedule, setShowSchedule] = useState(false);

  return (
    <div className="p-2.5 border border-slate-200 bg-white rounded-xl" key={app.id}>
      <div className="flex items-center gap-3">
        <i className="fa text-red-500 fa-ban p-1.5 bg-red-100/80 rounded-md" />
        <div className="flex-grow overflow-hidden relative h-8 flex items-center">
          <span className="font-semibold text-slate-600 whitespace-nowrap absolute left-0">
            {app.identifier}
          </span>
          <div className="absolute right-0 top-0 h-full w-10 bg-gradient-to-r from-transparent to-white" />
        </div>
        {app.schedule ? (
          <button
            onClick={() => {
              setShowSchedule(!showSchedule);
            }}
            className="flex items-center px-2 py-1 rounded-full transition-[background-color,transform] duration-200 active:scale-90 gap-1.5 bg-slate-200/50 hover:bg-slate-200 active:bg-slate-300 select-none"
          >
            <ChevronDownIcon
              className={cx(
                `w-3.5 h-3.5 shrink-0 text-slate-500 transition-transform duration-200`,
                showSchedule && `rotate-180`,
              )}
              strokeWidth={2.5}
            />
            <span className="text-sm text-slate-600 font-medium">Scheduled</span>
          </button>
        ) : (
          <button
            onClick={() => {
              setSchedule(defaults.ruleSchedule());
              setShowSchedule(true);
            }}
            className="flex items-center px-2 py-1 rounded-full transition-[background-color,transform] duration-200 active:scale-90 gap-1.5 bg-slate-200/50 hover:bg-slate-200 active:bg-slate-300 select-none"
          >
            <ClockIcon
              className="w-3.5 h-3.5 shrink-0 text-slate-500"
              strokeWidth={2.5}
            />
            <span className="text-sm text-slate-600 font-medium">Always blocked</span>
          </button>
        )}
        <button
          className="w-7 h-7 flex justify-center items-center rounded-full text-slate-400 hover:bg-slate-100 hover:text-red-500 transition-colors duration-150 shrink-0"
          onClick={onDelete}
        >
          <TrashIcon className="w-4 h-4" strokeWidth={2.5} />
        </button>
      </div>
      {app.schedule && (
        <div
          className={cx(
            `flex justify-center items-center @container/schedule gap-2 transition-[height,margin-top,opacity] duration-200`,
            showSchedule
              ? `h-auto mt-2 opacity-100`
              : `h-0 mt-0 opacity-0 pointer-events-none`,
          )}
        >
          <ClockIcon className="w-4 text-slate-400 shrink-0" strokeWidth={2.5} />
          <SchedulePicker
            schedule={app.schedule}
            setSchedule={setSchedule}
            activeText={{ active: `Blocked`, inactive: `Allowed` }}
          />
          <button
            onClick={() => {
              setSchedule(undefined);
              setShowSchedule(false);
            }}
            className="h-5 w-5 flex justify-center items-center rounded-full hover:scale-150 hover:bg-slate-100 transition-[transform,background-color] duration-200 group active:scale-100 active:bg-slate-300"
          >
            <TrashIcon
              title="Remove schedule from keychain"
              strokeWidth={2}
              className="w-4 h-4 text-slate-400 group-hover:scale-75 transition-transform duration-200"
            />
          </button>
        </div>
      )}
    </div>
  );
};

export default BlockedAppCard;
