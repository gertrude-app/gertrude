import { Badge } from '@gertrude/ui';
import React from 'react';
import type { Device } from '#/components/types';
import { deviceImageUrl, deviceSubtitle, deviceTitle } from '#/components/utils';

interface Props {
  device: Device;
  href: string;
}

const DeviceListRow: React.FC<Props> = ({ device, href }) => (
  <a
    href={href}
    className="flex items-center justify-between gap-3 rounded-xl border border-stone-200 bg-white p-3 pr-6 shadow shadow-stone-300/30 transition-[border-color,box-shadow] duration-100 hover:border-stone-300 hover:shadow-stone-300/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-300/80"
  >
    <div className="flex min-w-0 items-center gap-3">
      <div className="flex h-10 w-12 shrink-0 items-center justify-center text-stone-700">
        <img
          src={deviceImageUrl(device.type, device.modelIdentifier)}
          alt=""
          className="h-9 w-11 object-contain drop-shadow-sm"
        />
      </div>
      <div className="min-w-0 flex flex-col">
        <span className="truncate font-medium text-stone-900">{deviceTitle(device)}</span>
        <span className="truncate text-sm text-stone-500">{deviceSubtitle(device)}</span>
      </div>
    </div>
    <Badge
      size="small"
      color={device.type === `mac` && device.online ? `green` : `neutral`}
    >
      {device.type === `mac`
        ? device.online
          ? `Online`
          : `Offline`
        : device.type === `iphone`
          ? `iPhone`
          : `iPad`}
    </Badge>
  </a>
);

export default DeviceListRow;
