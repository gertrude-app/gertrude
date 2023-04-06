import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

interface Props {
  status: 'good' | 'bad' | 'warning';
  title: string;
  description?: string;
  action?: {
    label: string;
    icon: string;
    onClick: () => void;
  };
}

const HealthCheckItem: React.FC<Props> = ({ status, title, description, action }) => {
  let iconColor = ``;
  let icon = ``;
  switch (status) {
    case `good`:
      iconColor = `bg-green-500`;
      icon = `fa-solid fa-check`;
      break;
    case `bad`:
      iconColor = `bg-red-500`;
      icon = `fa-solid fa-times`;
      break;
    case `warning`:
      iconColor = `bg-yellow-400`;
      icon = `fa-solid fa-minus`;
      break;
  }

  return (
    <div className="flex items-center p-2 rounded-xl bg-slate-50 dark:bg-slate-800/30">
      <div
        className={cx(`w-6 h-6 rounded-full flex justify-center items-center`, iconColor)}
      >
        <i className={cx(`text-white dark:text-slate-900`, icon)} />
      </div>
      <div className="flex-grow ml-4">
        <h3 className="font-medium text-slate-800 dark:text-slate-200">{title}</h3>
        <p className="text-slate-500 dark:text-slate-400">{description}</p>
      </div>
      {action && (
        <Button type="button" onClick={action.onClick} color="tertiary" size="small">
          <i className={`fa-solid fa-${action.icon} mr-2`} />
          {action.label}
        </Button>
      )}
    </div>
  );
};

export default HealthCheckItem;
