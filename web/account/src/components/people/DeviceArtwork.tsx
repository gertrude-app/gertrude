import { HStack } from '@gertrude/ui';
import { LaptopIcon, type LucideIcon, SmartphoneIcon, TabletIcon } from 'lucide-react';
import React from 'react';
import { deviceImageUrl } from '#/components/utils';

interface ArtworkDevice {
  type: `mac` | `iphone` | `ipad`;
  modelIdentifier: string;
}

interface Props {
  device: ArtworkDevice;
  size?: `small` | `large` | `card`;
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
  const wrapperClass =
    size === `card`
      ? `h-12 w-16 shrink-0`
      : size === `large`
        ? `h-10 w-12 shrink-0`
        : `h-5.5 w-7 shrink-0`;
  const fallbackClass =
    size === `card`
      ? `h-8 w-8 text-stone-500`
      : size === `large`
        ? `h-8 w-8 text-stone-500`
        : `h-5 w-5 text-stone-500`;
  const imageClass =
    size === `card`
      ? `h-12 w-16 object-contain drop-shadow-sm`
      : size === `large`
        ? `h-9 w-11 object-contain drop-shadow-sm`
        : `h-5.5 w-7 object-contain drop-shadow-sm`;

  return (
    <HStack justify="center" align="center" className={wrapperClass}>
      {showFallback ? (
        <FallbackIcon className={fallbackClass} aria-hidden="true" />
      ) : (
        <img
          src={imageUrl}
          alt=""
          className={imageClass}
          onError={() => setFailedUrl(imageUrl)}
        />
      )}
    </HStack>
  );
};

export default DeviceArtwork;
