import React from 'react';
import cx from 'clsx';
import {
  LaptopIcon,
  MonitorSmartphoneIcon,
  PlusIcon,
  ScanEyeIcon,
  SettingsIcon,
  SmartphoneIcon,
} from 'lucide-react';
import { Button, inflect } from '@gertrude/ui';
import type { Child, Device } from '#/lib/mock-data';

interface Props {
  child: Child;
}

const ChildCard: React.FC<Props> = ({ child }) => {
  return (
    <div className="flex flex-col border border-stone-200 rounded-2xl shadow-md shadow-stone-300/30 bg-white">
      <div className="p-4 flex-grow flex flex-col gap-3">
        <div className="flex flex-col">
          <span className="text-lg font-medium">{child.name}</span>
          <span className="text-xs text-stone-500 -mt-0.25">
            {child.devices.length} {inflect('Device', child.devices.length)}
          </span>
        </div>
        {child.devices.length > 0 ? (
          <div className="flex flex-col gap-2">
            {child.devices.map((d) => (
              <DeviceCard device={d} childName={child.name} />
            ))}
          </div>
        ) : (
          <div className="flex flex-col items-center bg-stone-50 py-6 rounded-xl bg-dots">
            <MonitorSmartphoneIcon className="text-stone-600 w-6 h-6" />
            <span className="font-medium text-stone-900 mt-2">No Devices</span>
            <span className="text-sm text-stone-500 mb-4">
              Add a device to get started protecting {child.name}.
            </span>
            <Button type="link" href="/children" icon={PlusIcon} variant="primary">
              Add Device
            </Button>
          </div>
        )}
      </div>
      <div className="flex justify-end items-center gap-2 bg-stone-50 p-2 rounded-b-2xl border-t border-stone-200">
        <Button type="link" href="/children" icon={SettingsIcon} variant="ghost">
          Settings
        </Button>
        {child.devices.some((d) => d.type === 'mac') && (
          <Button type="link" href="/children" icon={ScanEyeIcon}>
            Monitor
          </Button>
        )}
      </div>
    </div>
  );
};

interface DeviceCardProps {
  device: Device;
  childName: string;
}

const DeviceCard: React.FC<DeviceCardProps> = ({ device, childName }) => {
  return (
    <div
      className={cx(
        'p-0.25 rounded-[13px]',
        device.type === 'mac' && device.online
          ? 'bg-gradient-to-r from-stone-200 via-stone-200 to-violet-300/80'
          : 'bg-stone-200',
      )}
    >
      <div className="flex items-center gap-3 bg-stone-50 py-2 pl-3 pr-4 rounded-xl relative overflow-hidden">
        {device.type === 'mac' ? (
          <LaptopIcon className="text-stone-700 w-5 h-5" />
        ) : (
          <SmartphoneIcon className="text-stone-700 w-5 h-5" />
        )}
        <div className="flex flex-col flex-grow">
          <span className="font-medium text-stone-900 text-sm">
            {device.type === 'mac'
              ? (device.name ?? device.modelName)
              : `${childName}'s ${device.modelName}`}
          </span>
          <span className="text-xs text-stone-500">
            {device.type === 'mac'
              ? `${device.name ? `${device.modelName} • ` : ''}macOS ${device.macOSVersion}`
              : `${device.type === 'iphone' ? 'iOS' : 'iPadOS'} ${device.iOSVersion}`}
          </span>
        </div>
        {device.type === 'mac' && (
          <>
            <div className="flex items-center gap-1.5">
              <div
                className={cx(
                  'w-1.5 h-1.5 rounded-full',
                  device.online ? 'bg-violet-500' : 'bg-stone-300',
                )}
              />
              <span
                className={cx(
                  'text-xs font-medium',
                  device.online ? 'text-violet-600' : 'text-stone-400',
                )}
              >
                {device.online ? 'Online' : 'Offline'}
              </span>
            </div>
            {device.online && (
              <div className="w-40 h-30 absolute bg-violet-500 -right-10 rounded-full blur-[40px] opacity-10" />
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default ChildCard;
