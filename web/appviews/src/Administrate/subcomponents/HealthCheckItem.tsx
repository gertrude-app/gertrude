import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type { ItemData as HealthCheckItemData } from '../HealthChecker';
import type { HealthCheckAction } from '../administrate-store';

type Props = HealthCheckItemData & {
  emit(action: HealthCheckAction): unknown;
};

const HealthCheckItem: React.FC<Props> = (props) => {
  let iconColor: string;
  let icon: string;
  switch (props.state) {
    case `ok`:
      iconColor = `bg-green-500`;
      icon = `fa-solid fa-check translate-x-[0.5px]`;
      break;
    case `fail`:
      iconColor = `bg-red-500`;
      icon = `fa-solid fa-times translate-x-[0.5px]`;
      break;
    case `warn`:
      iconColor = `bg-yellow-400`;
      icon = `fa-solid fa-minus`;
      break;
    case `checking`:
      iconColor = `bg-purple-500 dark:bg-purple-800`;
      icon = `fa-solid fa-sync animate-spin dark:text-slate-100`;
      break;
    case `unexpected`:
      iconColor = `bg-gray-500/90`;
      icon = `fa-solid fa-exclamation translate-x-[0.5px]`;
      break;
  }

  const button = getButton(props);
  const message = getMessage(props);

  return (
    <div className="flex items-center p-2 rounded-xl bg-slate-50 dark:bg-slate-800/30">
      <div
        className={cx(`w-6 h-6 rounded-full flex justify-center items-center`, iconColor)}
      >
        <i className={cx(`text-white dark:text-slate-900`, icon)} />
      </div>
      <div className="flex-grow ml-4">
        <h3 className="font-medium text-slate-800 dark:text-slate-200">{props.title}</h3>
        {message && (
          <p
            className="text-slate-500 dark:text-slate-400"
            dangerouslySetInnerHTML={{ __html: message }}
          />
        )}
      </div>
      {button && (
        <Button
          type="button"
          onClick={() => props.emit(button.action)}
          color="tertiary"
          size="small"
        >
          <i className={`fa-solid fa-${button.icon} mr-2`} />
          {button.label}
        </Button>
      )}
    </div>
  );
};

// helpers

function getButton(
  props: Props,
): { action: HealthCheckAction; label: string; icon: string } | undefined {
  if (props.state === `warn` || props.state === `fail`) {
    return props.button;
  }
  return undefined;
}

function getMessage(props: Props): string | undefined {
  switch (props.state) {
    case `ok`:
      return props.message;
    case `fail`:
      return props.message;
    case `warn`:
      return props.message;
    case `unexpected`:
      return props.message ?? `Unexpected check error, please try again`;
    default:
      return undefined;
  }
}

export default HealthCheckItem;
