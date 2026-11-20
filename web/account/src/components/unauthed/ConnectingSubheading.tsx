import { AppIcon } from '@gertrude/ui';
import cx from 'clsx';
import { SmartphoneIcon, TabletIcon } from 'lucide-react';
import React from 'react';
import type { ConnectingDevice } from '#/lib/authRedirect';
import { deviceImageUrl } from '#/components/utils';
import { gertrudeApps } from '#/lib/gertrudeApps';

interface Props {
  device: ConnectingDevice;
}

const ConnectingSubheading: React.FC<Props> = ({ device }) => {
  const app = gertrudeApps[device.app];
  return (
    <>
      to connect{` `}
      <Named
        iconClassName="top-[0.09em]"
        icon={
          <AppIcon
            src={app.icon}
            outlined={app.iconOutlined}
            className="!size-4.5 !rounded-[5px]"
          />
        }
      >
        {app.shortName}
        {!device.deviceName && <Period />}
      </Named>
      {device.deviceName ? (
        <>
          {` `}on your{` `}
          <Named icon={<DeviceIcon device={device} />}>
            {device.deviceName}
            <Period />
          </Named>
        </>
      ) : null}
    </>
  );
};

export default ConnectingSubheading;

const Named: React.FC<{
  icon: React.ReactNode;
  iconClassName?: string;
  children: React.ReactNode;
}> = ({ icon, iconClassName, children }) => (
  <span className="mx-0.5 inline-flex items-baseline gap-1 whitespace-nowrap font-medium text-stone-800">
    <span className={cx(`relative self-center`, iconClassName)}>{icon}</span>
    {children}
  </span>
);

const Period: React.FC = () => (
  <span className="-ml-1 font-normal text-stone-500">.</span>
);

const DeviceIcon: React.FC<{ device: ConnectingDevice }> = ({ device }) => {
  const isIPad = (device.modelIdentifier ?? device.deviceName ?? ``).startsWith(`iPad`);
  const imageUrl =
    device.modelIdentifier &&
    deviceImageUrl(isIPad ? `ipad` : `iphone`, device.modelIdentifier);
  const [failedUrl, setFailedUrl] = React.useState<string>();
  if (!imageUrl || failedUrl === imageUrl) {
    const Icon = isIPad ? TabletIcon : SmartphoneIcon;
    return <Icon className="size-4 text-stone-500" aria-hidden="true" />;
  }
  return (
    <img
      src={imageUrl}
      alt=""
      className="h-4.5 w-4 object-contain"
      onError={() => setFailedUrl(imageUrl)}
    />
  );
};
