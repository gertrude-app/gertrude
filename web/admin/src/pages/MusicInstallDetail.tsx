import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import type { TimelineEvent } from '../lib/format';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ConnectedAccountBadge from '../components/ConnectedAccountBadge';
import DetailPageHeader from '../components/DetailPageHeader';
import ErrorState from '../components/ErrorState';
import EventTimeline from '../components/EventTimeline';
import { MusicIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Section from '../components/Section';
import StatusPill from '../components/StatusPill';
import { formatDate } from '../lib/format';
import {
  MUSIC_INSTALL_STATUS_STYLES,
  UNKNOWN_MUSIC_INSTALL_STATUS_STYLE,
} from '../lib/musicInstallStatus';

interface MusicEvent extends TimelineEvent {
  level: string;
  domain?: string;
}

const getEventColor = (event: TimelineEvent): string => {
  const musicEvent = event as MusicEvent;
  if (musicEvent.level === `error` || musicEvent.level === `critical`) {
    return `bg-red-400`;
  }
  if (musicEvent.level === `warning`) {
    return `bg-amber-400`;
  }
  if (musicEvent.domain === `subscription`) {
    return `bg-violet-500`;
  }
  return `bg-slate-300`;
};

const getEventBadge = (event: MusicEvent): string => event.domain ?? event.level;

const getEventBadgeClass = (event: MusicEvent): string => {
  if (event.domain === `subscription`) {
    return `bg-violet-100 text-violet-700`;
  }
  switch (event.level) {
    case `critical`:
    case `error`:
      return `bg-red-100 text-red-700`;
    case `warning`:
      return `bg-amber-100 text-amber-700`;
    default:
      return `bg-slate-100 text-slate-600`;
  }
};

const MusicInstallDetail: React.FC = () => {
  const { deviceId } = useParams<{ deviceId: string }>();
  const [data, setData] = useState<T.MusicInstallDetail.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      if (!deviceId) return;

      setLoading(true);
      setError(null);

      const result = await client.musicInstallDetail({ deviceId });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load install details`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [deviceId]);

  if (loading) {
    return <LoadingState context="install details" gradient="violet" />;
  }

  if (error) {
    return <ErrorState context="install details" error={error} />;
  }

  if (!data) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <DetailPageHeader
        backTo="/music"
        icon={MusicIcon}
        iconGradient="from-fuchsia-500 to-violet-600"
        iconShadow="shadow-fuchsia-500/20"
        title="Music Install Details"
        subtitle={
          <>
            <code className="font-mono">{data.deviceId.slice(0, 8).toLowerCase()}</code>
            {` `}&middot;{` `}
            {data.deviceType}
            {` `}&middot;{` `}
            iOS {data.iosVersion}
            {` `}&middot;{` `}v{data.appVersion}
            {` `}&middot;{` `}
            {formatDate(data.firstLaunch)}
          </>
        }
        badge={
          <div className="flex flex-wrap items-center gap-2">
            <StatusPill
              status={data.status}
              styles={MUSIC_INSTALL_STATUS_STYLES}
              fallback={UNKNOWN_MUSIC_INSTALL_STATUS_STYLE}
            />
            {data.connectedAccount && (
              <ConnectedAccountBadge account={data.connectedAccount} />
            )}
          </div>
        }
      />

      {data.events.length > 0 ? (
        <EventTimeline
          events={data.events}
          getEventColor={getEventColor}
          renderEventMeta={(event) => {
            const musicEvent = event as MusicEvent;
            return (
              <span
                className={`text-xs px-1.5 py-0.5 rounded ${getEventBadgeClass(
                  musicEvent,
                )}`}
              >
                {getEventBadge(musicEvent)}
              </span>
            );
          }}
        />
      ) : (
        <Section title="Event Timeline">
          <div className="text-sm text-slate-500 py-2">No music events recorded yet</div>
        </Section>
      )}

      <Section title={`Approved Albums (${data.approvedAlbums.length})`}>
        {data.approvedAlbums.length > 0 ? (
          <div className="divide-y divide-slate-100">
            {data.approvedAlbums.map((album, index) => (
              <div key={`${album.title}-${album.artistName}-${index}`} className="py-3">
                <div className="flex items-center gap-3">
                  {album.artworkUrl ? (
                    <img
                      src={album.artworkUrl}
                      alt=""
                      className="w-11 h-11 rounded-lg object-cover bg-slate-100"
                    />
                  ) : (
                    <div className="w-11 h-11 rounded-lg bg-fuchsia-100 flex items-center justify-center">
                      <MusicIcon className="w-5 h-5 text-fuchsia-600" />
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="font-medium text-slate-900 truncate">
                      {album.title}
                    </div>
                    <div className="text-sm text-slate-500 truncate">
                      {album.artistName}
                      {album.trackCount ? ` · ${album.trackCount} tracks` : ``}
                    </div>
                  </div>
                  <div className="text-sm text-slate-400 whitespace-nowrap">
                    {formatDate(album.approvedAt)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-sm text-slate-500 py-2">No approved albums yet</div>
        )}
      </Section>
    </div>
  );
};

export default MusicInstallDetail;
