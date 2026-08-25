import type { DevicesPageData } from '#/components/devices/types';
import type { GetDevices } from '@shared/pairql/src/account';

export function toDevicesPageData(output: GetDevices.Output): DevicesPageData {
  return {
    macs: output.macs.map((device) => ({
      ...device,
      type: `mac`,
      people: device.people.map((person) => ({ ...person })),
    })),
    mobileDevices: output.mobileDevices.map((device) => ({
      ...device,
      person: { ...device.person },
      connectedApps: [...device.connectedApps],
    })),
  };
}
