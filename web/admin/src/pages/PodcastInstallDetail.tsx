import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import type { TimelineEvent } from '../lib/format';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import DetailPageHeader from '../components/DetailPageHeader';
import ErrorState from '../components/ErrorState';
import EventTimeline from '../components/EventTimeline';
import { LinkIcon, MicIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import { formatDate } from '../lib/format';

interface PodcastEvent extends TimelineEvent {
  kind: string;
}

const getEventColor = (event: TimelineEvent): string => {
  const podcastEvent = event as PodcastEvent;
  if (podcastEvent.kind === `subscription`) return `bg-green-500`;
  if (podcastEvent.kind === `error`) return `bg-red-400`;
  if (podcastEvent.kind === `unexpected`) return `bg-amber-400`;
  if (event.eventId === `27c4f26a`) return `bg-emerald-500`;
  return `bg-slate-300`;
};

const getKindBadgeClass = (kind: string): string => {
  switch (kind) {
    case `subscription`:
      return `bg-green-100 text-green-700`;
    case `error`:
      return `bg-red-100 text-red-700`;
    case `unexpected`:
      return `bg-amber-100 text-amber-700`;
    default:
      return `bg-slate-100 text-slate-600`;
  }
};

const PodcastInstallDetail: React.FC = () => {
  const { installId } = useParams<{ installId: string }>();
  const [data, setData] = useState<T.PodcastInstallDetail.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      if (!installId) return;

      setLoading(true);
      setError(null);

      const result = await client.podcastInstallDetail({ installId });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load install details`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [installId]);

  if (loading) {
    return <LoadingState context="install details" gradient="green" />;
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
        backTo="/podcasts"
        icon={MicIcon}
        iconGradient="from-emerald-400 to-green-500"
        iconShadow="shadow-emerald-500/20"
        title="Install Details"
        subtitle={
          <>
            <code className="font-mono">{data.installId.slice(0, 8).toLowerCase()}</code>
            {` `}&middot;{` `}
            {data.deviceType}
            {` `}&middot;{` `}
            iOS {data.iosVersion}
            {` `}&middot;{` `}v{data.appVersion}
          </>
        }
        badge={
          data.isPaid && (
            <span className="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium bg-green-100 text-green-700">
              Paid Subscriber
            </span>
          )
        }
      />

      <EventTimeline
        events={data.events}
        getEventColor={getEventColor}
        renderEventMeta={(event) => {
          const podcastEvent = event as PodcastEvent;
          return (
            <span
              className={`text-xs px-1.5 py-0.5 rounded ${getKindBadgeClass(
                podcastEvent.kind,
              )}`}
            >
              {podcastEvent.kind}
            </span>
          );
        }}
      />

      {data.subscribedFeeds.length > 0 && (
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
          <div className="px-4 sm:px-6 py-4 border-b border-slate-100">
            <h2 className="font-display font-medium text-slate-900">
              Subscribed Feeds ({data.subscribedFeeds.length})
            </h2>
          </div>
          <div className="divide-y divide-slate-100">
            {data.subscribedFeeds.map((feed, index) => (
              <a
                key={index}
                href={feed.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-3 sm:gap-4 px-4 sm:px-6 py-3 hover:bg-emerald-50 transition-colors group"
              >
                <span className="text-sm text-slate-400 whitespace-nowrap">
                  {formatDate(feed.subscribedAt)}
                </span>
                <LinkIcon className="w-4 h-4 text-slate-400 group-hover:text-emerald-500 flex-shrink-0" />
                <span className="text-sm font-mono text-slate-600 group-hover:text-emerald-700 break-all">
                  {feed.url}
                </span>
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default PodcastInstallDetail;
