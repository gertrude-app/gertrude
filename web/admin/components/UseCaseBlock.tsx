import React from 'react';
import type { AdminData } from '@/lib/types';
import { getStatus, isActive } from '@/lib/utils';

const UseCaseBlock: React.FC<{ admins: AdminData[] }> = ({ admins }) => {
  const activeAdmins = admins.filter(isActive);
  const justMonitoring = activeAdmins.filter((a) => getStatus(a) === `justMonitoring`);
  const justKeychains = activeAdmins.filter((a) => getStatus(a) === `justKeychains`);
  const supers = activeAdmins.filter((a) => getStatus(a) === `superUser`);

  return (
    <div className="flex flex-col items-center border border-slate-200 rounded-3xl px-8 py-4 gap-6">
      <h3 className="text-xl font-semibold">Use case among active users</h3>
      <div className="flex-grow flex flex-col gap-1">
        <div
          className="flex items-center gap-2"
          style={{
            height: `${(justMonitoring.length * 100) / activeAdmins.length}%`,
          }}
        >
          <div className="h-full bg-violet-500 rounded w-40 shrink-0" />
          <span className="text-slate-500">
            {((justMonitoring.length * 100) / activeAdmins.length).toFixed(2)}%{` `}
            monitoring
          </span>
        </div>
        <div
          className="flex items-center gap-2"
          style={{
            height: `${(justKeychains.length * 100) / activeAdmins.length}%`,
          }}
        >
          <div className="h-full bg-fuchsia-500 rounded w-40 shrink-0" />
          <span className="text-slate-500">
            {((justKeychains.length * 100) / activeAdmins.length).toFixed(2)}%{` `}
            keychains
          </span>
        </div>
        <div
          className="flex items-center gap-2"
          style={{
            height: `${(supers.length * 100) / activeAdmins.length}%`,
          }}
        >
          <div className="h-full bg-violet-500 rounded w-40 shrink-0" />
          <span className="text-slate-500">
            {((supers.length * 100) / activeAdmins.length).toFixed(2)}%{` `}
            both
          </span>
        </div>
      </div>
    </div>
  );
};

export default UseCaseBlock;
