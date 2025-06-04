import React from 'react';
import cx from 'classnames';

interface Props {
  time: ISODateString;
  protocol: `udp` | `tcp` | `other`;
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
  <div
    className="flex relative items-center justify-between p-3 rounded-xl group even:bg-slate-50 dark:even:bg-[#141A2F] hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer overflow-x-hidden shrink-0"
    onClick={onSelectToggle}
  >
    <div className="flex items-center">
      <div
        className={cx(
          `border w-6 h-6 rounded-full transition-[border-color,background-color] duration-100 hover:scale-105 cursor-pointer flex justify-center items-center shrink-0`,
          selected
            ? `bg-violet-700 border-violet-700`
            : `border-slate-300 hover:border-slate-400 dark:border-slate-600 dark:hover:border-slate-500`,
        )}
      >
        <i
          className={cx(
            selected ? `scale-100 dark:text-white` : `scale-50 opacity-0`,
            `fa-solid fa-check text-white even:text-slate-50 text-sm transition-[color,transform,opacity] duration-150`,
          )}
        />
      </div>
      <span className="text-xs text-slate-400/80 dark:text-slate-500 ml-4 font-mono">
        {new Date(time).toLocaleTimeString().replace(/ +/g, ``)}
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
      <div className="mx-6 flex-grow relative self-stretch flex items-center">
        <span className="text-sm font-mono text-slate-800 dark:text-slate-200 overflow-ellipsis overflow-hidden whitespace-nowrap">
          {target}
        </span>
      </div>
    </div>
    <div className="shrink-0 absolute right-0 overflow-hidden whitespace-nowrap text-ellipsis text-slate-400 dark:text-slate-500 font-medium flex">
      <div className="w-16 shrink-0 bg-gradient-to-r from-[#ffffff00] dark:from-[#0f172a00] group-odd:to-white dark:group-odd:to-slate-900 group-even:to-slate-50 dark:group-even:to-[#141A2E] group-hover:to-slate-100 dark:group-hover:to-slate-800" />
      <span className="shrink-0 group-even:bg-slate-50 group-odd:bg-white dark:group-even:bg-[#141A2E] dark:group-odd:bg-slate-900 group-hover:bg-slate-100 pr-4 dark:group-hover:bg-slate-800 pl-8">
        {app}
      </span>
    </div>
  </div>
);

export default BlockedRequest;
