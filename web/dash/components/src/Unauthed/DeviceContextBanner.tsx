import { iosDeviceType } from '@dash/utils';
import React from 'react';
import type { IOSDeviceType } from '@dash/utils';

type Props = {
  modelName: string;
  iosVersion?: string;
  label?: string;
  deviceType?: IOSDeviceType;
};

const DeviceContextBanner: React.FC<Props> = ({
  modelName,
  iosVersion,
  label = `Signup to supervise:`,
  deviceType: deviceTypeProp,
}) => {
  const deviceType = deviceTypeProp ?? iosDeviceType(modelName);
  return (
    <div className="my-1 relative overflow-hidden rounded-2xl bg-gradient-to-br from-violet-500 to-fuchsia-500 p-[1px] shadow-lg shadow-violet-500/20">
      <div className="relative rounded-[15px] bg-white px-4 py-3">
        <div className="flex items-center gap-4">
          <div className="relative">
            <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 blur-sm opacity-40" />
            <div className="relative w-11 h-11 rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 flex items-center justify-center shadow-md">
              {deviceType === `iPad` ? (
                <IPadIcon className="w-6 h-6 text-white" />
              ) : (
                <IPhoneIcon className="w-6 h-6 text-white" />
              )}
            </div>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold uppercase tracking-wide text-violet-500">
              {label}
            </p>
            <p className="text-slate-800 font-semibold truncate">
              {modelName}
              {iosVersion && (
                <span className="text-slate-400 font-normal"> · iOS {iosVersion}</span>
              )}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

const IPhoneIcon: React.FC<{ className?: string }> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <rect width="12" height="20" x="6" y="2" rx="2" />
    <line x1="12" x2="12.01" y1="18" y2="18" />
  </svg>
);

const IPadIcon: React.FC<{ className?: string }> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <rect width="16" height="20" x="4" y="2" rx="2" />
    <line x1="12" x2="12.01" y1="18" y2="18" />
  </svg>
);

export default DeviceContextBanner;
