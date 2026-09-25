import { HStack } from '@gertrude/ui';
import { LaptopIcon, type LucideIcon, SmartphoneIcon, TabletIcon } from 'lucide-react';
import React from 'react';
import { deviceImageUrl } from '#/components/utils';

interface ArtworkDevice {
  type: `mac` | `iphone` | `ipad`;
  modelIdentifier: string;
}

type ArtworkSize = `small` | `medium` | `large` | `card` | `pairing`;

interface Props {
  device: ArtworkDevice;
  size?: ArtworkSize;
}

const sizeClasses: Record<
  ArtworkSize,
  { wrapper: string; fallback: string; image: string }
> = {
  small: {
    wrapper: `h-5.5 w-7 shrink-0`,
    fallback: `h-5 w-5 text-stone-500`,
    image: `h-5.5 w-7 object-contain drop-shadow-sm`,
  },
  medium: {
    wrapper: `h-8 w-10 shrink-0`,
    fallback: `h-7 w-7 text-stone-500`,
    image: `h-7 w-9 object-contain drop-shadow-sm`,
  },
  large: {
    wrapper: `h-10 w-12 shrink-0`,
    fallback: `h-8 w-8 text-stone-500`,
    image: `h-9 w-11 object-contain drop-shadow-sm`,
  },
  card: {
    wrapper: `h-12 w-16 shrink-0`,
    fallback: `h-8 w-8 text-stone-500`,
    image: `h-12 w-16 object-contain drop-shadow-sm`,
  },
  pairing: {
    wrapper: `h-10 w-auto shrink-0`,
    fallback: `h-8 w-8 text-stone-500`,
    image: `h-10 w-auto drop-shadow-sm`,
  },
};

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
  const classes = sizeClasses[size];

  return (
    <HStack justify="center" align="center" className={classes.wrapper}>
      {showFallback ? (
        <FallbackIcon className={classes.fallback} aria-hidden="true" />
      ) : (
        <img
          src={imageUrl}
          alt=""
          className={classes.image}
          onError={() => setFailedUrl(imageUrl)}
        />
      )}
    </HStack>
  );
};

export default DeviceArtwork;
