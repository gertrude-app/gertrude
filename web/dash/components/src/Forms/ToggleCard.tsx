import { ExclamationTriangleIcon } from '@heroicons/react/20/solid';
import { Toggle } from '@shared/components';
import cx from 'classnames';
import React from 'react';

interface Props {
  title: string;
  description: string;
  enabled: boolean;
  setEnabled: (enabled: boolean) => unknown;
  warning?: string;
  children?: React.ReactNode;
  className?: string;
}

const ToggleCard: React.FC<Props> = ({
  title,
  description,
  enabled,
  setEnabled,
  warning,
  children,
  className,
}) => (
  <div
    className={cx(
      `mt-3 p-4 sm:p-6 rounded-xl bg-slate-100 border`,
      warning ? `border-amber-300` : `border-transparent`,
      !!children && `overflow-hidden relative`,
      className,
    )}
  >
    <div className="flex justify-between items-center gap-10">
      <div>
        <h3 className="font-medium text-slate-700 leading-tight">{title}</h3>
        <p className="text-slate-500 text-sm mt-1">{description}</p>
      </div>
      <Toggle enabled={enabled} setEnabled={setEnabled} />
    </div>
    {warning && (
      <div className="inline-flex items-center gap-1.5 mt-3 px-3 py-1.5 bg-amber-50/70 border border-amber-200/60 text-amber-700 text-sm rounded-full">
        <ExclamationTriangleIcon className="w-3.5 h-3.5 flex-shrink-0" />
        <span>{warning}</span>
      </div>
    )}
    {children}
  </div>
);

export default ToggleCard;
