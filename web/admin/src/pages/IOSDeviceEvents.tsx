import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { TimelineEvent } from '../lib/format';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import DetailPageHeader from '../components/DetailPageHeader';
import ErrorState from '../components/ErrorState';
import EventTimeline from '../components/EventTimeline';
import { SmartphoneIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import { timeAgo } from '../lib/format';

const ERROR_EVENT_IDS = [
  `e2e02460`,
  `004d0d89`,
  `2bcf3d96`,
  `e220a765`,
  `6f0a66e4`,
  `24220209`,
  `104a7ef6`,
  `d2e2ee7c`,
  `f4ed05fd`,
  `fa49f256`,
  `0dc1632a`,
  `321558ed`,
  `93958bd1`,
  `ae941213`,
  `d9dfd021`,
  `498796d3`,
  `c4d92e1a`,
  `df3914fa`,
  `b7f3a2d1`,
  `fdab6cff`,
  `8d4a445b`,
  `2c3a4481`,
];

const WARNING_EVENT_IDS = [
  `30fac4e6`,
  `3c4772ad`,
  `a21c9040`,
  `daa8c7fd`,
  `e30624c6`,
  `c98b9525`,
  `23c207e2`,
  `d9e93a4b`,
  `ffff30ac`,
  `7c039b10`,
  `00b0c478`,
  `94991de7`,
  `016d03db`,
  `d3b4f6e2`,
  `f9797be9`,
  `bcca235f`,
  `59d3c6d1`,
  `e81796af`,
];

const SUCCESS_EVENT_IDS = [
  `4a0c585f`,
  `adced334`,
  `021834f6`,
  `421d373b`,
  `bad8adcc`,
  `cb9cf096`,
  `fcba8692`,
  `a7e31b8f`,
  `09748184`,
  `1c6f6ca8`,
  `80451da8`,
];

const getEventColor = (event: TimelineEvent): string => {
  const { eventId } = event;
  if (eventId === `cdb31095`) return `bg-green-500`;
  if (eventId === `8d35f043`) return `bg-sky-500`;
  if (eventId === `f2c3863b`) return `bg-purple-400`;
  if (eventId === `6ed43005`) return `bg-green-500`;
  if (ERROR_EVENT_IDS.includes(eventId)) return `bg-red-400`;
  if (WARNING_EVENT_IDS.includes(eventId)) return `bg-amber-400`;
  if (SUCCESS_EVENT_IDS.includes(eventId)) return `bg-emerald-400`;
  return `bg-slate-300`;
};

const IOSDeviceEvents: React.FC = () => {
  const { vendorId } = useParams<{ vendorId: string }>();
  const [data, setData] = useState<T.IOSDeviceEvents.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      if (!vendorId) return;

      setLoading(true);
      setError(null);

      const result = await client.iOSDeviceEvents({ vendorId });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load device events`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [vendorId]);

  if (loading) {
    return <LoadingState context="device events" gradient="blue" />;
  }

  if (error) {
    return <ErrorState context="device events" error={error} />;
  }

  if (!data) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <DetailPageHeader
        backTo="/ios-devices"
        icon={SmartphoneIcon}
        iconGradient="from-sky-400 to-blue-500"
        iconShadow="shadow-sky-500/20"
        title="Device Events"
        subtitle={
          <>
            <code className="font-mono">{data.vendorId.slice(0, 8).toLowerCase()}</code>
            {` `}&middot;{` `}
            {data.modelName}
            {` `}&middot;{` `}
            iOS {data.iosVersion}
          </>
        }
        badge={
          <div className="flex flex-col items-end gap-1.5">
            {data.reachedOptOut && (
              <span className="inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium bg-green-100 text-green-700">
                Successfully Onboarded
              </span>
            )}
            {data.lastCheckin ? (
              <span className="text-xs text-slate-400">
                Last check-in: <span className="text-purple-400">{timeAgo(data.lastCheckin)}</span>
              </span>
            ) : (
              <span className="text-xs text-slate-300">No check-ins yet</span>
            )}
          </div>
        }
      />

      <EventTimeline events={data.events} getEventColor={getEventColor} />

      <div className="flex justify-between items-center pt-4 pb-8">
        <NavButton vendorId={data.nextVendorId} direction="prev" />
        <NavButton vendorId={data.prevVendorId} direction="next" />
      </div>
    </div>
  );
};

export default IOSDeviceEvents;

const NavButton: React.FC<{ vendorId?: string; direction: `prev` | `next` }> = ({
  vendorId,
  direction,
}) => {
  const label = direction === `prev` ? `\u2190 Previous Device` : `Next Device \u2192`;
  if (vendorId) {
    return (
      <Link
        to={`/ios/${vendorId}/events`}
        className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 hover:border-slate-300 transition-all"
      >
        {label}
      </Link>
    );
  }
  return (
    <span className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-300 bg-slate-50 border border-slate-100 rounded-lg cursor-default">
      {label}
    </span>
  );
};
