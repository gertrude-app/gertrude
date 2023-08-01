import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import { inflect } from '@shared/string';
import type { HealthCheck, HealthCheckAction } from '../administrate-store';
import HealthCheckItem from '../subcomponents/HealthCheckItem';
import HealthChecker from '../HealthChecker';

type Props = HealthCheck & {
  screenshotMonitoringEnabled: boolean;
  keystrokeMonitoringEnabled: boolean;
  installedAppVersion: string;
  emit(action: HealthCheckAction): unknown;
};

const HealthCheckScreen: React.FC<Props> = ({
  installedAppVersion,
  screenshotMonitoringEnabled,
  keystrokeMonitoringEnabled,
  emit,
  ...props
}) => {
  const health = new HealthChecker(
    props,
    installedAppVersion,
    screenshotMonitoringEnabled,
    keystrokeMonitoringEnabled,
  );

  return (
    <div className="h-full overflow-y-scroll appview:overflow-y-auto relative">
      <header className="flex items-center justify-between border-b p-4 border-slate-200 dark:border-slate-800 sticky bg-white dark:bg-slate-900 top-0 z-10">
        <div>
          <h2 className="text-2xl font-bold text-slate-800 dark:text-slate-100">
            Health check
          </h2>
          <span
            className={cx(
              `text-slate-600 dark:text-slate-400`,
              health.isChecking && `italic opacity-50`,
            )}
          >
            {health.isChecking
              ? `Checking...`
              : health.failingChecksCount
              ? `${health.failingChecksCount} ${inflect(
                  `failing check`,
                  health.failingChecksCount,
                )}!`
              : `Everything looks good!`}
          </span>
        </div>
        <Button
          type="button"
          onClick={() => emit(`recheckClicked`)}
          disabled={health.isChecking}
          color="secondary"
          size="small"
        >
          <i
            className={cx(`fa-solid fa-sync mr-2`, health.isChecking && `animate-spin`)}
          />
          {health.isChecking ? `Checking...` : `Recheck`}
        </Button>
      </header>
      <ul className="flex flex-col space-y-2 p-4">
        {health.items.map((item) => (
          <HealthCheckItem key={item.title} {...item} emit={emit} />
        ))}
      </ul>
    </div>
  );
};

export default HealthCheckScreen;
