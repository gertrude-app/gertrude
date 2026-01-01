import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { ArrowLeftIcon, ChevronRightIcon, SmartphoneIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';

const IOSDeviceJourney: React.FC = () => {
  const { vendorId } = useParams<{ vendorId: string }>();
  const [data, setData] = useState<T.IOSDeviceJourney.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [expandedEvents, setExpandedEvents] = useState<Set<string>>(new Set());

  const toggleExpanded = (eventId: string): void => {
    setExpandedEvents((prev) => {
      const next = new Set(prev);
      if (next.has(eventId)) {
        next.delete(eventId);
      } else {
        next.add(eventId);
      }
      return next;
    });
  };

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      if (!vendorId) return;

      setLoading(true);
      setError(null);

      const result = await client.iOSDeviceJourney({ vendorId });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load device journey`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [vendorId]);

  if (loading) {
    return <LoadingState context="device journey" gradient="blue" />;
  }

  if (error) {
    return <ErrorState context="device journey" error={error} />;
  }

  if (!data) {
    return null;
  }

  const formatTime = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleTimeString(`en-US`, {
      hour: `2-digit`,
      minute: `2-digit`,
      second: `2-digit`,
      hour12: false,
    });
  };

  const formatElapsed = (seconds: number): string => {
    if (seconds < 60) {
      return `+${seconds}s`;
    } else if (seconds < 3600) {
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return secs > 0 ? `+${mins}m ${secs}s` : `+${mins}m`;
    } else if (seconds < 86400) {
      const hours = Math.floor(seconds / 3600);
      const mins = Math.floor((seconds % 3600) / 60);
      return mins > 0 ? `+${hours}h ${mins}m` : `+${hours}h`;
    } else {
      const days = Math.floor(seconds / 86400);
      const hours = Math.floor((seconds % 86400) / 3600);
      return hours > 0 ? `+${days}d ${hours}h` : `+${days}d`;
    }
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString(`en-US`, {
      year: `numeric`,
      month: `short`,
      day: `numeric`,
    });
  };

  type Event = T.IOSDeviceJourney.Output[`events`][number];

  const groupEventsByDate = (events: Event[]): Map<string, Event[]> => {
    const groups = new Map<string, Event[]>();
    for (const event of events) {
      const dateKey = new Date(event.createdAt).toDateString();
      const existing = groups.get(dateKey) ?? [];
      existing.push(event);
      groups.set(dateKey, existing);
    }
    return groups;
  };

  const getEventColor = (eventId: string): string => {
    if (eventId === `cdb31095`) return `bg-green-500`;
    if (eventId === `8d35f043`) return `bg-sky-500`;
    const errors = [
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
    ];
    if (errors.includes(eventId)) return `bg-red-400`;
    const warnings = [
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
    ];
    if (warnings.includes(eventId)) return `bg-amber-400`;
    const successes = [
      `4a0c585f`,
      `adced334`,
      `021834f6`,
      `421d373b`,
      `bad8adcc`,
      `cb9cf096`,
    ];
    if (successes.includes(eventId)) return `bg-emerald-400`;
    return `bg-slate-300`;
  };

  const eventGroups = groupEventsByDate(data.events);

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-4">
        <Link
          to="/ios-devices"
          className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 bg-slate-100 hover:bg-slate-200 rounded-lg transition-all group"
        >
          <ArrowLeftIcon className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
          <span>Back</span>
        </Link>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg shadow-sky-500/20">
            <SmartphoneIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="font-display font-semibold text-slate-900 text-2xl">
              Device Journey
            </h1>
            <p className="text-sm text-slate-500">
              <code className="font-mono">{data.vendorId.slice(0, 8).toLowerCase()}</code>
              {` `}&middot;{` `}
              {data.deviceType}
              {` `}&middot;{` `}
              iOS {data.iosVersion}
            </p>
          </div>
        </div>
        {data.reachedOptOut && (
          <span className="ml-auto inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium bg-green-100 text-green-700">
            Successfully Onboarded
          </span>
        )}
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-100">
          <h2 className="font-display font-medium text-slate-900">
            Event Timeline ({data.events.length} events)
          </h2>
        </div>

        <div className="divide-y divide-slate-100">
          {Array.from(eventGroups.entries()).map(([dateKey, events]) => (
            <div key={dateKey} className="px-6 py-4">
              <div className="flex items-center gap-2 mb-4">
                <div className="w-2 h-2 rounded-full bg-slate-400" />
                <span className="text-sm font-medium text-slate-700">
                  {formatDate(events[0]?.createdAt ?? ``)}
                </span>
                <span className="text-xs text-slate-400">
                  ({events.length} event{events.length !== 1 ? `s` : ``})
                </span>
              </div>

              <div className="ml-0.5 border-l-2 border-slate-200 pl-4 space-y-3">
                {events.map((event) => {
                  const isExpanded = expandedEvents.has(event.id);
                  return (
                    <div key={event.id} className="relative flex items-start gap-3">
                      <div
                        className={`absolute -left-[21px] w-3 h-3 rounded-full ${getEventColor(event.eventId)} ring-2 ring-white`}
                      />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-baseline gap-2">
                          <code className="text-sm text-slate-400 font-mono">
                            {formatTime(event.createdAt)}
                          </code>
                          <a
                            href={`https://github.com/search?q=repo%3Agertrude-app%2Fgertrude%20${event.eventId}&type=code`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm text-violet-400 hover:text-violet-600 font-mono transition-colors"
                          >
                            {event.eventId}
                          </a>
                          {event.elapsedSeconds !== undefined &&
                            event.elapsedSeconds !== null && (
                              <span className="text-sm text-slate-400 font-mono">
                                {formatElapsed(event.elapsedSeconds)}
                              </span>
                            )}
                        </div>
                        <div className="flex items-center gap-1 mt-0.5">
                          {event.detail && (
                            <button
                              onClick={() => toggleExpanded(event.id)}
                              className="p-0.5 -ml-1 hover:bg-slate-100 rounded transition-colors"
                            >
                              <ChevronRightIcon
                                className={`w-4 h-4 text-slate-400 transition-transform ${isExpanded ? `rotate-90` : ``}`}
                              />
                            </button>
                          )}
                          <p className="text-base text-slate-700">{event.label}</p>
                        </div>
                        {event.detail && isExpanded && (
                          <p className="text-sm text-slate-500 mt-1 ml-4 font-mono break-all">
                            {event.detail}
                          </p>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default IOSDeviceJourney;
