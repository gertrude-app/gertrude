import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import type { Page } from '../Administrate';

interface Props {
  failingChecksCount: number;
  setPage: (page: Page) => void;
}

const HealthCheckPreviewBlock: React.FC<Props> = ({ failingChecksCount, setPage }) => {
  return (
    <div className="bg-white dark:bg-slate-800/50 rounded-xl shadow border-slate-200 dark:border-slate-700 border-[0.5px] p-4 flex-grow relative overflow-hidden">
      <div
        className={cx(
          `absolute top-1 right-1 w-10 h-10 bg-red-100 dark:bg-red-500/10 rounded-xl rounded-bl-3xl flex justify-center items-center`,
          failingChecksCount === 0 && `hidden`,
        )}
      >
        <i className="fa-solid fa-exclamation text-red-500 text-xl" />
      </div>
      <h3 className="text-lg font-bold text-slate-700 dark:text-slate-100 relative">
        {failingChecksCount === 0
          ? `Everything looks good!`
          : `Some health checks are failing`}
      </h3>
      <p className="text-slate-500 dark:text-slate-400 mt-0.5">
        {failingChecksCount === 0
          ? `All health checks are passing.`
          : `View health check to fix ${failingChecksCount} issues.`}
      </p>
      <Button
        type="button"
        onClick={() => setPage(`health_check`)}
        color={failingChecksCount === 0 ? `tertiary` : `warning`}
        size="small"
        className="absolute right-4 bottom-4"
      >
        See health check
      </Button>
    </div>
  );
};

export default HealthCheckPreviewBlock;
