import React from 'react';
import { Button } from '@shared/components';
import type { ChildComputerStatus } from '@dash/types';
import UserStatus from '../UserStatus';

interface Props {
  name?: string;
  id: string;
  modelTitle: string;
  modelIdentifier: string;
  user?: {
    name: string;
    status: ChildComputerStatus;
  };
}

const ComputerCard: React.FC<Props> = ({
  name,
  modelTitle,
  user,
  modelIdentifier,
  id,
}) => (
  <div className="border-[0.5px] border-slate-200 rounded-3xl shadow-lg shadow-slate-300/50 bg-white">
    <div className="p-6 flex justify-between items-center gap-4">
      <div>
        {user?.name && (
          <h3 className="text-sm font-semibold text-slate-500">
            {user.name} is using{!name && ` the`}
          </h3>
        )}
        <h2 className="text-2xl font-bold">{name || modelTitle}</h2>
        {name && <h3 className="text-sm text-slate-500">{modelTitle}</h3>}
      </div>
      <div className="w-20 h-20 flex justify-center items-center shrink-0">
        <img
          alt={modelTitle}
          src={`/macs/${modelIdentifier}.png`}
          className="max-h-full max-w-full"
        />
      </div>
    </div>
    <div className="py-3 pl-3 pr-5 border-t border-slate-200 rounded-b-3xl flex justify-between items-center @container">
      <UserStatus status={user?.status || { case: `offline` }} />
      <Button type="link" to={`/computers/${id}`} color="tertiary" size="small">
        <i className="fa-solid fa-pen mr-2" />
        Edit
      </Button>
    </div>
  </div>
);

export default ComputerCard;
