import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
  userName: string;
}

const UserBlock: React.FC<Props> = ({
  screenshotMonitoringEnabled,
  keystrokeMonitoringEnabled,
  userName,
}) => {
  const monitoringStyles = {
    screenshotButton: `bg-slate-200/70 text-slate-400 dark:bg-slate-800 dark:text-slate-600`,
    screenshotButtonText: `text-slate-500`,
    keystrokeIndicator: `bg-slate-200/70 text-slate-400 dark:bg-slate-800 dark:text-slate-600`,
    screenshotText: `text-slate-500 dark:text-slate-400`,
    keystrokeText: `text-slate-500 dark:text-slate-400`,
  };
  if (screenshotMonitoringEnabled) {
    monitoringStyles.screenshotButton = `bg-indigo-100 dark:bg-indigo-500/30 text-indigo-500 dark:text-indigo-400`;
    monitoringStyles.screenshotButtonText = `text-indigo-500`;
    monitoringStyles.screenshotText = `text-indigo-500`;
  }
  if (keystrokeMonitoringEnabled) {
    monitoringStyles.keystrokeIndicator = `bg-indigo-100 dark:bg-indigo-500/30 text-indigo-500 dark:text-indigo-400`;
    monitoringStyles.keystrokeText = `text-indigo-500`;
  }

  return (
    <div className="p-4 border-[0.5px] border-slate-200 dark:border-slate-700 dark:bg-slate-800/50 shadow rounded-xl relative overflow-hidden">
      <div className="flex justify-between items-stretch relative">
        <div className="flex flex-col justify-between">
          <h3 className="font-semibold text-xl text-slate-600 dark:text-slate-400">
            Connected to user{` `}
            <span className="font-black text-slate-900 dark:text-slate-100">
              {userName}
            </span>
          </h3>
          <div className="flex">
            <Button type="button" onClick={() => {}} color="tertiary" size="small">
              Connect to a different user
            </Button>
          </div>
        </div>
        <div className="flex flex-col items-end relative">
          <div className="flex space-x-4">
            <button
              className={cx(
                `rounded-full flex items-center transition-all duration-200 group w-8 hover:w-[182px] overflow-hidden active:scale-95`,
                monitoringStyles.screenshotButton,
              )}
            >
              <div className="w-8 h-8 rounded-full flex justify-center items-center shrink-0">
                <i className="fa-solid fa-binoculars" />
              </div>
              <span
                className={cx(
                  `opacity-0 transition duration-200 group-hover:opacity-100 text-sm pl-1 whitespace-nowrap`,
                  monitoringStyles.screenshotButtonText,
                )}
              >
                Take test screenshot
              </span>
            </button>
            <div
              className={cx(
                `w-8 h-8 rounded-full flex justify-center items-center`,
                monitoringStyles.keystrokeIndicator,
              )}
            >
              <i className="fa-solid fa-keyboard" />
            </div>
          </div>
          <div className="flex flex-col items-end mt-2">
            <p className="text-slate-400 dark:text-slate-500 text-sm italic -mb-0.5">
              Screenshot monitoring{` `}
              <span className={cx(`font-medium`, monitoringStyles.screenshotText)}>
                {screenshotMonitoringEnabled ? `enabled` : `disabled`}
              </span>
            </p>
            <p className="text-slate-400 dark:text-slate-500 text-sm italic">
              Keystroke monitoring{` `}
              <span className={cx(`font-medium`, monitoringStyles.keystrokeText)}>
                {keystrokeMonitoringEnabled ? `enabled` : `disabled`}
              </span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default UserBlock;
