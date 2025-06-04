import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';

export interface Props {
  title: string;
  children?: React.ReactNode;
  button?: {
    text: string;
    action: () => unknown;
    icon: string;
  };
  className?: string;
}

const ErrorBlock: React.FC<Props> = ({ title, children, button, className }) => (
  <div
    className={cx(
      `flex flex-col items-center justify-center p-4 rounded-2xl border border-red-200 dark:border-red-700/50 bg-red-50/30 dark:bg-red-600/5 flex-grow`,
      className,
    )}
  >
    <span className="font-bold text-lg text-slate-700 dark:text-white/80 mb-2">
      {title}
    </span>
    {children && <span className="text-red-500 mb-4 dark:text-red-400">{children}</span>}
    {button && (
      <Button type="button" onClick={button.action} color="warning" size="small">
        <i className={`fa-solid ${button.icon} mr-2`} />
        {button.text}
      </Button>
    )}
  </div>
);

export default ErrorBlock;
