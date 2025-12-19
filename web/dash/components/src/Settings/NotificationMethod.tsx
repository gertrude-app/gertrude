import { prettyE164 } from '@dash/utils';
import { Button, isScreenshotTest } from '@shared/components';
import cx from 'classnames';
import React from 'react';

type Props = {
  method: `email` | `slack` | `text`;
  value: string;
  deletable: boolean;
  onDelete(): unknown;
  inUse: boolean;
  createNotification(): unknown;
};

const NotificationMethod: React.FC<Props> = ({
  deletable,
  onDelete,
  method,
  value,
  inUse,
  createNotification,
}) => (
  <li className="pl-4 xs:pr-2 py-2 odd:bg-slate-100 xs:odd:bg-slate-50 rounded-xl max-w-4xl flex flex-row justify-between items-center group">
    <div className="flex-grow overflow-hidden pl-2 -ml-2 relative">
      {!inUse && <span className="font-semibold text-red-500 text-sm">Not in use</span>}
      <h2 className={cx(!inUse && `opacity-30`, `flex items-center`)}>
        <div
          className={cx(
            `w-2 h-2 rounded-full mr-2 relative shrink-0`,
            inUse ? `bg-violet-500` : `bg-slate-400/70`,
          )}
        >
          <div
            className={cx(
              `w-2 h-2 bg-violet-500 rounded-full absolute left-0 top-0`,
              !isScreenshotTest() && `animate-ping`,
              !inUse && `hidden`,
            )}
          />
        </div>
        <span className="capitalize font-medium text-slate-600">{method}</span>
        <span className="text-violet-700 font-semibold pl-1.5">{prettyE164(value)}</span>
      </h2>
      <div className="absolute right-0 top-0 w-20 h-full bg-gradient-to-r from-transparent to-white group-odd:to-slate-100 group-even:to-slate-50 xs:group-even:to-white xs:group-odd:to-slate-50" />
    </div>
    <div className="flex items-center gap-3 ml-1.5 shrink-0">
      {inUse ? (
        <div></div>
      ) : (
        <Button type="button" onClick={createNotification} color="secondary" size="small">
          <i className="fa fa-plus" />
        </Button>
      )}
      <Button
        type="button"
        onClick={deletable ? onDelete : () => {}}
        color="warning"
        size="small"
        disabled={!deletable}
      >
        <i className="fa fa-trash" />
      </Button>
    </div>
  </li>
);

export default NotificationMethod;
