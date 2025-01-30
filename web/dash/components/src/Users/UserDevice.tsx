import React from 'react';
import cx from 'classnames';
import { Link } from 'react-router-dom';
import type { ChildComputerStatus } from '@dash/types';

type Props = {
  id: UUID;
  deviceId: UUID;
  modelTitle: string;
  modelIdentifier: string;
  name?: string;
  status: ChildComputerStatus;
  className?: string;
};

const UserDevice: React.FC<Props> = ({
  deviceId,
  modelTitle,
  modelIdentifier,
  status,
  className,
  name,
}) => (
  <Link
    to={`/computers/${deviceId}`}
    className={cx(
      `rounded-2xl p-2 px-3 bg-white border border-slate-200 transition-[background-color] duration-100 hover:bg-slate-50 flex justify-between items-center gap-6`,
      className,
    )}
  >
    <div className="flex items-center gap-4 sm:gap-6">
      <div className="rounded-full bg-slate-100 w-14 h-14 shrink-0 flex justify-center items-center">
        <img
          src={`/macs/${modelIdentifier}.png`}
          alt={modelTitle}
          className="max-w-[60%] max-h-[60%] grayscale-[50%]"
        />
      </div>
      <div>
        <h3 className="text-slate-900 text-lg font-bold line-clamp-1">
          {name || modelTitle}
        </h3>
        {name && <h4 className="text-sm text-slate-500 line-clamp-1">{modelTitle}</h4>}
      </div>
    </div>
    {status.case !== `offline` && (
      <>
        <div className="flex items-center gap-2 mr-2">
          <span className={`text-sm text-slate-500 hidden xs:block`}>online</span>
          <div className={`w-3 h-3 rounded-full bg-green-400`} />
        </div>
      </>
    )}
  </Link>
);

export default UserDevice;
