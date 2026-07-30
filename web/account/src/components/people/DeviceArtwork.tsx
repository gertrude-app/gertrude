import { HStack } from '@gertrude/ui';
import { LaptopIcon, type LucideIcon, SmartphoneIcon, TabletIcon } from 'lucide-react';
import React from 'react';
import type { Device } from '#/components/types';
import { deviceImageUrl } from '#/components/utils';

interface Props {
  device: Device;
  size?: `small` | `large`;
}

const DeviceArtwork: React.FC<Props> = ({ device, size = `small` }) => {
  const imageUrl = deviceImageUrl(device.type, device.modelIdentifier);
  const [failedUrl, setFailedUrl] = React.useState<string>();
  const FallbackIcon: LucideIcon =
    device.type === `mac`
      ? LaptopIcon
      : device.type === `iphone`
        ? SmartphoneIcon
        : TabletIcon;
  const showFallback =
    device.modelIdentifier.endsWith(`,unknown`) || failedUrl === imageUrl;
  const large = size === `large`;

  return (
    <HStack
      justify="center"
      align="center"
      className={large ? `h-10 w-12 shrink-0` : `h-5.5 w-7 shrink-0`}
    >
      {showFallback ? (
        <FallbackIcon
          className={large ? `h-8 w-8 text-stone-500` : `h-5 w-5 text-stone-500`}
          aria-hidden="true"
        />
      ) : (
        <img
          src={imageUrl}
          alt=""
          className={
            large
              ? `h-9 w-11 object-contain drop-shadow-sm`
              : `h-5.5 w-7 object-contain drop-shadow-sm`
          }
          onError={() => setFailedUrl(imageUrl)}
        />
      )}
    </HStack>
  );
};

export default DeviceArtwork;
