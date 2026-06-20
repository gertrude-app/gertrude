import { Badge, Button, EmptyState, inflect } from '@gertrude/ui';
import cx from 'clsx';
import {
  MonitorSmartphoneIcon,
  PlusIcon,
  ScanEyeIcon,
  SettingsIcon,
  SmartphoneIcon,
} from 'lucide-react';
import React from 'react';
import type { Device, PersonWithDevices } from '#/lib/mock';
import { personActivityHref } from '#/lib/activity-helpers';
import { macImageUrl } from '#/lib/device-images';

interface Props {
  person: PersonWithDevices;
}

const getDeviceKey = (device: Device): string => device.id;

const PersonCard: React.FC<Props> = ({ person }) => (
  <div className="flex flex-col border border-stone-200 rounded-2xl shadow-md shadow-stone-300/30 bg-white">
    <div className="p-3 @lg/main:p-4 flex-grow flex flex-col gap-2">
      <div className="flex flex-col @2xl/main:flex-row gap-3">
        <div
          className={cx(
            `flex flex-col gap-3`,
            person.screenshot ? `@2xl/main:w-1/2` : `w-full`,
          )}
        >
          <span className="text-stone-900 text-lg font-medium">{person.name}</span>
          {person.devices.length > 0 ? (
            <div className="flex flex-col gap-2">
              {person.devices.map((d) => (
                <DeviceRow key={getDeviceKey(d)} device={d} />
              ))}
            </div>
          ) : (
            <EmptyState
              icon={MonitorSmartphoneIcon}
              title="No Devices"
              description={`Add a device to get started protecting ${person.name}.`}
              button={{
                text: `Add Device`,
                type: `link`,
                href: `/people`,
                icon: PlusIcon,
                variant: `primary`,
              }}
            />
          )}
        </div>
        {person.screenshot && (
          <div className="flex flex-col justify-center items-center @2xl/main:w-1/2 gap-2 p-4 h-[100%]">
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
            <span className="text-xs text-stone-600">{person.screenshot.recency}</span>
          </div>
        )}
      </div>
    </div>
    <div className="flex justify-between items-center bg-stone-50 py-2 px-3 @lg/main:px-4 rounded-b-2xl border-t border-stone-200">
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
      <div />
      <div className="flex items-center gap-2">
        <Button
          type="link"
          href={`/people/${person.id}`}
          icon={SettingsIcon}
          variant="ghost"
        >
          Settings
        </Button>
        {person.devices.some((d) => d.type === `mac`) && (
          <Button type="link" href={personActivityHref(person.id)} icon={ScanEyeIcon}>
            Monitor
          </Button>
        )}
      </div>
    </div>
  </div>
);

interface DeviceCardProps {
  device: Device;
}

const DeviceRow: React.FC<DeviceCardProps> = ({ device }) => (
  <div className="flex items-center gap-2.5 rounded-xl border border-stone-200 bg-stone-50 py-1.5 pl-2.5 pr-4">
    <div className="flex h-5.5 w-7 shrink-0 items-center justify-center">
      {device.type === `mac` ? (
        <img
          src={macImageUrl(device.modelIdentifier)}
          alt=""
          className="h-5.5 w-7 object-contain drop-shadow-sm"
        />
      ) : (
        <SmartphoneIcon className="text-stone-700 w-4.5 h-4.5" />
      )}
    </div>
    <div className="flex flex-col flex-grow">
      <span className="font-medium text-stone-900 text-sm">
        {device.type === `mac`
          ? (device.name ?? device.modelName)
          : `${device.modelName}`}
      </span>
      <span className="text-xs text-stone-500">
        {device.type === `mac`
          ? `${device.name ? `${device.modelName} • ` : ``}macOS ${device.macOSVersion}`
          : `${device.type === `iphone` ? `iOS` : `iPadOS`} ${device.iOSVersion}`}
      </span>
    </div>
    {device.type === `mac` && (
      <Badge size="small" color={device.online ? `green` : `neutral`}>
        {device.online ? `Online` : `Offline`}
      </Badge>
    )}
  </div>
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
  const recencyText: string =
    recencyInMinutes === 0
      ? `Listening now`
      : `${recencyInMinutes} ${inflect(`minute`, recencyInMinutes)} ago`;

  return (
    <div className="flex items-center gap-2">
      <img
        src={artworkUrl}
        alt={`${title} artwork`}
        className="w-8 h-8 rounded-md border-[0.5px] border-stone-400 shadow shadow-stone-300/30"
      />
      <div className="hidden @2xl/main:flex flex-col">
        <span className="text-xs font-medium text-stone-900">{title}</span>
        <span className="text-xs text-stone-600">
          {subtitle} • {recencyText}
        </span>
      </div>
      {recencyInMinutes === 0 && (
        <div className="media-waveform ml-1 @2xl/main:ml-4" aria-hidden="true">
          <div className="media-waveform-bar" />
          <div className="media-waveform-bar" />
          <div className="media-waveform-bar" />
          <div className="media-waveform-bar" />
        </div>
      )}
    </div>
  );
};

export default PersonCard;
