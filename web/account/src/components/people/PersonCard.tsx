import {
  Badge,
  Button,
  Card,
  EmptyState,
  HStack,
  Spacer,
  Stack,
  Text,
  VStack,
  inflect,
} from '@gertrude/ui';
import { MonitorSmartphoneIcon, PlusIcon, ScanEyeIcon, SettingsIcon } from 'lucide-react';
import React from 'react';
import type { Device, PersonCardPerson } from '#/components/types';
import { deviceImageUrl } from '#/components/utils';

interface Props {
  person: PersonCardPerson;
  settingsHref: string;
  monitorHref?: string;
  addDeviceHref?: string;
}

const PersonCard: React.FC<Props> = ({
  person,
  settingsHref,
  monitorHref,
  addDeviceHref,
}) => (
  <Card preset="big" padding={0}>
    <Card.Body padding={{ default: 3, '@lg/main': 4 }}>
      <Stack direction={{ default: `vertical`, '@2xl/main': `horizontal` }} gap={3}>
        <VStack gap={3} className={person.screenshot ? `@2xl/main:w-1/2` : `w-full`}>
          <Text variant="heading">{person.name}</Text>
          {person.devices.length > 0 ? (
            <VStack gap={2}>
              {person.devices.map((device) => (
                <DeviceRow key={device.id} device={device} />
              ))}
            </VStack>
          ) : (
            <EmptyState
              icon={MonitorSmartphoneIcon}
              title="No Devices"
              description={`Add a device to get started protecting ${person.name}.`}
              button={
                addDeviceHref
                  ? {
                      text: `Add Device`,
                      type: `link`,
                      href: addDeviceHref,
                      icon: PlusIcon,
                      variant: `primary`,
                    }
                  : undefined
              }
            />
          )}
        </VStack>
        {person.screenshot && (
          <VStack
            justify="center"
            align="center"
            gap={2}
            className="@2xl/main:w-1/2 p-4 h-[100%]"
          >
            <div className="relative">
              <img
                src={person.screenshot.url}
                alt=""
                aria-hidden="true"
                className="rounded absolute blur-[10px] opacity-50"
              />
              <img
                src={person.screenshot.url}
                alt={`${person.name}'s recent screenshot`}
                className="rounded relative"
              />
            </div>
            <Text variant="caption">{person.screenshot.recency}</Text>
          </VStack>
        )}
      </Stack>
    </Card.Body>
    <Card.Footer className="flex items-center @lg/main:px-4">
      {person.musicListening && (
        <MediaCard
          title={person.musicListening.trackName}
          subtitle={person.musicListening.artistName}
          artworkUrl={person.musicListening.albumArtUrl}
          recencyInMinutes={person.musicListening.recencyInMinutes}
        />
      )}
      {person.podcastListening && !person.musicListening && (
        <MediaCard
          title={person.podcastListening.title}
          subtitle={person.podcastListening.podcastName}
          artworkUrl={person.podcastListening.artworkUrl}
          recencyInMinutes={person.podcastListening.recencyInMinutes}
        />
      )}
      <Spacer />
      <HStack gap={2}>
        <Button type="link" href={settingsHref} icon={SettingsIcon} variant="ghost">
          Settings
        </Button>
        {person.devices.some((device) => device.type === `mac`) && monitorHref && (
          <Button type="link" href={monitorHref} icon={ScanEyeIcon}>
            Monitor
          </Button>
        )}
      </HStack>
    </Card.Footer>
  </Card>
);

interface DeviceRowProps {
  device: Device;
}

const DeviceRow: React.FC<DeviceRowProps> = ({ device }) => (
  <HStack
    align="center"
    gap={2.5}
    className="rounded-xl border border-stone-200 bg-stone-50 py-1.5 pl-2.5 pr-4"
  >
    <HStack justify="center" align="center" className="h-5.5 w-7 shrink-0">
      <img
        src={deviceImageUrl(device.type, device.modelIdentifier)}
        alt=""
        className="h-5.5 w-7 object-contain drop-shadow-sm"
      />
    </HStack>
    <VStack className="flex-grow">
      <Text variant="bodyStrong">
        {device.type === `mac`
          ? (device.name ?? device.modelName)
          : `${device.modelName}`}
      </Text>
      <Text variant="captionMuted">
        {device.type === `mac`
          ? `${device.name ? `${device.modelName} • ` : ``}macOS ${device.macOSVersion}`
          : `${device.type === `iphone` ? `iOS` : `iPadOS`} ${device.iOSVersion}`}
      </Text>
    </VStack>
    {device.type === `mac` && (
      <Badge size="small" color={device.online ? `green` : `neutral`}>
        {device.online ? `Online` : `Offline`}
      </Badge>
    )}
  </HStack>
);

interface MediaCardProps {
  title: string;
  subtitle: string;
  artworkUrl: string;
  recencyInMinutes: number;
}

const MediaCard: React.FC<MediaCardProps> = ({
  title,
  subtitle,
  artworkUrl,
  recencyInMinutes,
}) => {
  const recencyText =
    recencyInMinutes === 0
      ? `Listening now`
      : `${recencyInMinutes} ${inflect(`minute`, recencyInMinutes)} ago`;

  return (
    <HStack align="center" gap={2}>
      <img
        src={artworkUrl}
        alt={`${title} artwork`}
        className="w-8 h-8 rounded-md border-[0.5px] border-stone-400 shadow shadow-stone-300/30"
      />
      <VStack hideBelow="@2xl/main">
        <Text variant="captionStrong">{title}</Text>
        <Text variant="captionMuted">
          {subtitle} • {recencyText}
        </Text>
      </VStack>
      {recencyInMinutes === 0 && (
        <div className="media-waveform ml-1 @2xl/main:ml-4" aria-hidden="true">
          <div className="media-waveform-bar" />
          <div className="media-waveform-bar" />
          <div className="media-waveform-bar" />
          <div className="media-waveform-bar" />
        </div>
      )}
    </HStack>
  );
};

export default PersonCard;
