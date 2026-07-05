import { Toggle } from '@gertrude/ui';
import cx from 'clsx';
import { InfoIcon } from 'lucide-react';
import React from 'react';

type Props = {
  title: string;
  description: string;
  children?: React.ReactNode;
  warning?: string;
  showWarning?: boolean;
} & (
  | {
      type: `toggle`;
      enabled: boolean;
      setEnabled: (enabled: boolean) => void;
    }
  | {
      type: `alwaysOn`;
    }
);

const SettingsRow: React.FC<Props> = (props) => {
  const showWarning = !!(props.warning && props.showWarning);

  return (
    <div className="flex flex-col @lg/main:border-x border-y border-stone-200 @lg/main:rounded-md -mx-3 @lg/main:mx-0">
      <div
        className={cx(
          `bg-stone-50 rounded-t-md flex flex-col border-stone-200`,
          showWarning ? `border-b` : `rounded-b-md`,
        )}
      >
        <div className="flex justify-between items-center p-3 pr-5 gap-5">
          <div className="flex flex-col">
            <span className="text-sm font-medium text-stone-800">{props.title}</span>
            <span className="text-sm text-stone-600">{props.description}</span>
          </div>
          {props.type === `toggle` && (
            <Toggle checked={props.enabled} setChecked={props.setEnabled} />
          )}
        </div>
        {props.children && (
          <div
            className={cx(
              `overflow-hidden transition-[height,opacity] duration-200`,
              props.type === `alwaysOn` || props.enabled
                ? `h-auto opacity-100`
                : `h-0 opacity-0`,
            )}
          >
            <div className="px-3 pb-3">{props.children}</div>
          </div>
        )}
      </div>
      {showWarning && (
        <div className="p-3 flex items-start gap-3 bg-amber-200/30 rounded-b-md">
          <InfoIcon className="h-4 w-4 text-amber-800 mt-0.5 shrink-0" />
          <p className="text-amber-800 text-sm">{props.warning}</p>
        </div>
      )}
    </div>
  );
};

export default SettingsRow;
