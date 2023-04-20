import React from 'react';
import cx from 'classnames';

interface Props {
  time: ISODateString;
  protocol: 'udp' | 'tcp' | 'other';
  target: string;
  app: string;
  selected: boolean;
  onSelectToggle(): unknown;
}

const BlockedRequest: React.FC<Props> = ({
  time,
  protocol,
  target,
  app,
  selected,
  onSelectToggle,
}) => (
  <div className="flex items-center justify-between p-3 rounded-xl even:bg-slate-50 dark:even:bg-slate-800/50">
    <div className="flex items-center">
      <div
        className={cx(
          `border w-6 h-6 rounded-full transition duration-100 hover:scale-105 cursor-pointer flex justify-center items-center shrink-0`,
          selected
            ? `bg-violet-700 border-violet-700`
            : `border-slate-300 hover:border-slate-400 dark:border-slate-600 dark:hover:border-slate-500`,
        )}
        onClick={onSelectToggle}
      >
        <i
          className={cx(
            `fa-solid fa-check text-white even:text-slate-50 text-sm transition duration-150`,
            selected ? `scale-100 dark:text-white` : `scale-50 dark:text-slate-900`,
          )}
        />
      </div>
      <span className="text-xs text-slate-400/80 dark:text-slate-500 ml-4 font-mono">
        {time}
      </span>
      <span
        className={cx(
          `text-white font-medium uppercase text-sm px-2 rounded-full ml-6 opacity-80 border`,
          protocol === `tcp`
            ? `bg-indigo-500 border-indigo-500 dark:bg-indigo-500/20 dark:border-indigo-400 dark:text-indigo-200`
            : `bg-fuchsia-500 border-fuchsia-500 dark:bg-fuchsia-500/20 dark:border-fuchsia-400 dark:text-fuchsia-200`,
        )}
      >
        {protocol}
      </span>
      <span className="text-sm font-mono ml-6 text-slate-800 dark:text-slate-200 max-w-sm text-ellipsis overflow-hidden block whitespace-nowrap">
        {target}
      </span>
    </div>
    <span className="shrink-0 max-w-[220px] overflow-hidden whitespace-nowrap text-ellipsis text-slate-400 dark:text-slate-500 font-medium">
      {app}
    </span>
  </div>
);

export default BlockedRequest;
