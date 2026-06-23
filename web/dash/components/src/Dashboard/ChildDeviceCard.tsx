import cx from 'classnames';
import React from 'react';
import type { ChildComputerStatus, DashboardWidgets_v3 } from '@dash/types';

type Child = DashboardWidgets_v3.Output[`children`][number];
type DeviceInfo = Child[`devices`][number];

type Props = Child;

const ChildDeviceCard: React.FC<Props> = ({ name, devices }) => (
  <div className="py-3 first:pt-0 last:pb-0">
    <div className="flex items-center gap-2.5 mb-2 ml-1.5">
      <div className="w-6 h-6 rounded-full bg-violet-100 flex items-center justify-center shrink-0">
        <i className="fa-solid fa-user text-violet-300 text-[10px]" />
      </div>
      <span className="font-semibold text-slate-800 text-[17px]">{name}</span>
    </div>
    <div className="flex flex-col gap-1 ml-9">
      {devices.map((device, i) => (
        <DeviceRow key={i} device={device} />
      ))}
    </div>
  </div>
);

export default ChildDeviceCard;

const DeviceRow: React.FC<{ device: DeviceInfo }> = ({ device }) => {
  const info =
    device.iosStatus != null
      ? iosStatusInfo(device.iosStatus)
      : macStatusInfo(device.macStatus ?? { case: `offline` });
  return (
    <div className="flex items-center gap-2 bg-slate-50 rounded-lg px-3 py-1.5">
      <i
        className={cx(
          device.platform === `mac` ? `fa-solid fa-laptop` : `fa-solid fa-mobile-screen`,
          `text-slate-400 text-sm w-4 text-center`,
        )}
      />
      <span className="text-sm text-slate-700 flex-grow truncate">
        {device.deviceName}
      </span>
      <span
        className={cx(
          `text-[11px] font-semibold px-2 py-0.5 rounded-full shrink-0`,
          info.pillClasses,
        )}
      >
        {info.text}
      </span>
    </div>
  );
};

function iosStatusInfo(status: `setupComplete` | `pendingSetup`): {
  pillClasses: string;
  text: string;
} {
  switch (status) {
    case `setupComplete`:
      return { pillClasses: `bg-green-200/50 text-green-700`, text: `Connected` };
    case `pendingSetup`:
      return { pillClasses: `bg-amber-50 text-amber-700`, text: `Pending setup` };
  }
}

function macStatusInfo(status: ChildComputerStatus): {
  pillClasses: string;
  text: string;
} {
  switch (status.case) {
    case `filterOn`:
      return { pillClasses: `bg-green-50 text-green-700`, text: `Filter on` };
    case `filterOff`:
      return { pillClasses: `bg-red-50 text-red-700`, text: `Filter off` };
    case `filterSuspended`:
      return { pillClasses: `bg-yellow-50 text-yellow-700`, text: `Suspended` };
    case `offline`:
      return { pillClasses: `bg-slate-100 text-slate-500`, text: `Offline` };
    case `downtime`:
      return { pillClasses: `bg-purple-50 text-purple-700`, text: `Downtime` };
    case `downtimePaused`:
      return { pillClasses: `bg-yellow-50 text-yellow-700`, text: `Paused` };
    case `unfiltered`:
      return { pillClasses: `bg-orange-50 text-orange-700`, text: `Unfiltered` };
  }
}
