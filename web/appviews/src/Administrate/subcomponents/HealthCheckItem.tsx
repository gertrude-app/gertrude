import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  status: 'checking' | 'ok' | 'warn' | 'fail' | 'errorDetermining';
  title: string;
  description?: string;
  warnDescription?: string;
  failDescription?: string;
  errorDeterminingDescription?: string;
  actionLevel?: 'warn' | 'fail' | 'never';
  actionLabel: string;
  actionIcon: string;
  onAction: () => void;
}

const HealthCheckItem: React.FC<Props> = ({
  status,
  title,
  description,
  warnDescription,
  failDescription,
  errorDeterminingDescription,
  actionLevel = `fail`,
  actionLabel,
  actionIcon,
  onAction,
}) => {
  let iconColor: string;
  let icon: string;
  let subtitle: string | undefined;
  switch (status) {
    case `ok`:
      iconColor = `bg-green-500`;
      icon = `fa-solid fa-check translate-x-[0.5px]`;
      subtitle = description;
      break;
    case `fail`:
      iconColor = `bg-red-500`;
      icon = `fa-solid fa-times translate-x-[0.5px]`;
      subtitle = failDescription ?? description;
      break;
    case `warn`:
      iconColor = `bg-yellow-400`;
      icon = `fa-solid fa-minus`;
      subtitle = warnDescription ?? description;
      break;
    case `checking`:
      iconColor = `bg-purple-500 dark:bg-purple-800`;
      icon = `fa-solid fa-sync animate-spin dark:text-slate-100`;
      break;
    case `errorDetermining`:
      iconColor = `bg-gray-500/90`;
      icon = `fa-solid fa-exclamation translate-x-[0.5px]`;
      subtitle =
        errorDeterminingDescription ?? `Unexpected check error, please try again`;
      break;
  }

  const showAction =
    actionLevel !== `never` &&
    ((actionLevel === `warn` && (status === `warn` || status === `fail`)) ||
      status === `fail`);

  return (
    <div className="flex items-center p-2 rounded-xl bg-slate-50 dark:bg-slate-800/30">
      <div
        className={cx(`w-6 h-6 rounded-full flex justify-center items-center`, iconColor)}
      >
        <i className={cx(`text-white dark:text-slate-900`, icon)} />
      </div>
      <div className="flex-grow ml-4">
        <h3 className="font-medium text-slate-800 dark:text-slate-200">{title}</h3>
        {subtitle && <p className="text-slate-500 dark:text-slate-400">{subtitle}</p>}
      </div>
      {showAction && (
        <Button type="button" onClick={onAction} color="tertiary" size="small">
          <i className={`fa-solid fa-${actionIcon} mr-2`} />
          {actionLabel}
        </Button>
      )}
    </div>
  );
};

export default HealthCheckItem;
