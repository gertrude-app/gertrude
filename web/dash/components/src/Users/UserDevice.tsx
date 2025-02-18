import React from 'react';
import cx from 'classnames';
import { Link } from 'react-router-dom';
import type { ChildComputerStatus } from '@dash/types';
import UserStatus from '../UserStatus';

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
      `rounded-2xl p-2 px-2 xs:px-3 bg-white border border-slate-200 transition-[background-color] duration-100 hover:bg-slate-50 flex justify-between items-center gap-6 @container`,
      className,
    )}
  >
    <div className="flex items-center gap-3 xs:gap-4 sm:gap-6">
      <div className="rounded-full bg-slate-100 w-8 xs:w-14 h-8 xs:h-14 shrink-0 flex justify-center items-center">
        <img
          src={`/macs/${modelIdentifier}.png`}
          alt={modelTitle}
          className="max-w-[60%] max-h-[60%] grayscale-[50%]"
        />
      </div>
      <div>
        <h3 className="text-slate-900 xs:text-lg font-bold line-clamp-1 -mb-0.5 xs:mb-0">
          {name || modelTitle}
        </h3>
        {name && <h4 className="text-sm text-slate-500 line-clamp-1">{modelTitle}</h4>}
      </div>
    </div>
    <UserStatus status={status} />
  </Link>
);

export default UserDevice;
