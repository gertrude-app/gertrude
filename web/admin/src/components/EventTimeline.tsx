import React, { useState } from 'react';
import {
  type TimelineEvent,
  formatDate,
  formatElapsed,
  formatTime,
  groupEventsByDate,
} from '../lib/format';
import { ChevronRightIcon } from './Icons';

interface EventTimelineProps {
  events: TimelineEvent[];
  getEventColor: (event: TimelineEvent) => string;
  renderEventMeta?: (event: TimelineEvent) => React.ReactNode;
}

const EventTimeline: React.FC<EventTimelineProps> = ({
  events,
  getEventColor,
  renderEventMeta,
}) => {
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

  const eventGroups = groupEventsByDate(events);

  return (
    <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 border-b border-slate-100">
        <h2 className="font-display font-medium text-slate-900">
          Event Timeline ({events.length} events)
        </h2>
      </div>

      <div className="divide-y divide-slate-100">
        {Array.from(eventGroups.entries()).map(([dateKey, groupEvents]) => (
          <div key={dateKey} className="px-4 sm:px-6 py-4">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-2 h-2 rounded-full bg-slate-400" />
              <span className="text-sm font-medium text-slate-700">
                {formatDate(groupEvents[0]?.createdAt ?? ``)}
              </span>
              <span className="text-xs text-slate-400">
                ({groupEvents.length} event{groupEvents.length !== 1 ? `s` : ``})
              </span>
            </div>

            <div className="ml-0.5 border-l-2 border-slate-200 pl-4 space-y-3">
              {groupEvents.map((event) => {
                const isExpanded = expandedEvents.has(event.id);
                return (
                  <div key={event.id} className="relative flex items-start gap-3">
                    <div
                      className={`absolute -left-[21px] w-3 h-3 rounded-full ${getEventColor(
                        event,
                      )} ring-2 ring-white`}
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
                        <code className="text-xs sm:text-sm text-slate-400 font-mono">
                          {formatTime(event.createdAt)}
                        </code>
                        <a
                          href={`https://github.com/search?q=repo%3Agertrude-app%2Fgertrude%20${event.eventId}&type=code`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs sm:text-sm text-violet-400 hover:text-violet-600 font-mono transition-colors"
                        >
                          {event.eventId}
                        </a>
                        {renderEventMeta?.(event)}
                        {event.elapsedSeconds !== undefined &&
                          event.elapsedSeconds !== null && (
                            <span className="text-xs sm:text-sm text-slate-400 font-mono">
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
                              className={`w-4 h-4 text-slate-400 transition-transform ${
                                isExpanded ? `rotate-90` : ``
                              }`}
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
  );
};

export default EventTimeline;
