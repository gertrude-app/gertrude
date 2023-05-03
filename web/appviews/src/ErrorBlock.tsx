import { Button } from '@shared/components';
import React from 'react';

interface Props {
  title: string;
  message?: string;
  buttonText: string;
  buttonAction(): unknown;
  buttonIcon: string;
}

const ErrorBlock: React.FC<Props> = ({
  title,
  message,
  buttonText,
  buttonAction,
  buttonIcon,
}) => (
  <div className="flex flex-col items-center p-4 rounded-2xl border border-red-200 dark:border-red-700/50 bg-red-50/30 dark:bg-red-600/5 flex-grow">
    <span className="font-bold text-lg text-slate-700 dark:text-white/80">{title}</span>
    {message && <span className="text-red-500 mb-4 dark:text-red-400">{message}</span>}
    <Button type="button" onClick={buttonAction} color="warning" size="small">
      <i className={`fa-solid ${buttonIcon} mr-2`} />
      {buttonText}
    </Button>
  </div>
);

export default ErrorBlock;
