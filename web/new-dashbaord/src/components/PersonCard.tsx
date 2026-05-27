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
import { Button, EmptyState, inflect } from '@gertrude/ui';
import type { Person, Device } from '#/lib/mock-data';

interface Props {
  person: Person;
}

const PersonCard: React.FC<Props> = ({ person }) => {
  return (
    <div className="flex flex-col border border-stone-200 rounded-2xl shadow-md shadow-stone-300/30 bg-white">
      <div className="p-3 @lg/main:p-4 flex-grow flex flex-col gap-2">
        <div className="flex flex-col @2xl/main:flex-row gap-3">
          <div
            className={cx(
              'flex flex-col gap-3',
              person.screenshot ? '@2xl/main:w-1/2' : 'w-full',
            )}
          >
            <span className="text-stone-900 text-lg font-medium">{person.name}</span>
            {person.devices.length > 0 ? (
              <div className="flex flex-col gap-2">
                {person.devices.map((d) => (
                  <DeviceRow device={d} />
                ))}
              </div>
            ) : (
              <EmptyState
                icon={MonitorSmartphoneIcon}
                title="No Devices"
                description={`Add a device to get started protecting ${person.name}.`}
                button={{
                  text: 'Add Device',
                  href: '/people',
                  icon: PlusIcon,
                  variant: 'primary',
                }}
              />
            )}
          </div>
          {person.screenshot && (
            <div className="flex flex-col justify-center items-center @2xl/main:w-1/2 gap-2 p-4 h-[100%]">
              <div className="relative">
                <img
                  src={person.screenshot.url}
                  className="rounded absolute blur-[10px] opacity-50"
                />
                <img src={person.screenshot.url} className="rounded relative" />
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
          <Button type="link" href="/people" icon={SettingsIcon} variant="ghost">
            Settings
          </Button>
          {person.devices.some((d) => d.type === 'mac') && (
            <Button type="link" href="/people" icon={ScanEyeIcon}>
              Monitor
            </Button>
          )}
        </div>
      </div>
    </div>
  );
};

interface DeviceCardProps {
  device: Device;
}

const DeviceRow: React.FC<DeviceCardProps> = ({ device }) => {
  return (
    <div
      className={cx(
        'p-0.25 rounded-[13px]',
        device.type === 'mac' && device.online
          ? 'bg-gradient-to-r from-stone-200 via-stone-200 to-violet-300/80'
          : 'bg-stone-200',
      )}
    >
      <div className="flex items-center gap-2.5 bg-stone-50 py-1.5 pl-2.5 pr-4 rounded-xl relative overflow-hidden">
        {device.type === 'mac' ? (
          <LaptopIcon className="text-stone-700 w-4.5 h-4.5 shrink-0" />
        ) : (
          <SmartphoneIcon className="text-stone-700 w-4.5 h-4.5 shrink-0" />
        )}
        <div className="flex flex-col flex-grow">
          <span className="font-medium text-stone-900 text-sm">
            {device.type === 'mac'
              ? (device.name ?? device.modelName)
              : `${device.modelName}`}
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
  let recencyText: string =
    recencyInMinutes === 0
      ? 'Listening now'
      : `${recencyInMinutes} ${inflect('minute', recencyInMinutes)} ago`;

  return (
    <div className="flex items-center gap-2">
      <img
        src={artworkUrl}
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
