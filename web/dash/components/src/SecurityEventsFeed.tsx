import { ChevronRightIcon } from '@heroicons/react/24/outline';
import cx from 'classnames';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import type {
  SecurityEventSeverity,
  SecurityEventsFeed as SecurityEventsFeedPair,
} from '@dash/types';
import EmptyState from './EmptyState';
import PageHeading from './PageHeading';

export type SecurityEvent = SecurityEventsFeedPair.Output[number];

export type IpLocation = {
  city: string;
  region: string;
  countryCode: string;
};

type Props = {
  events: SecurityEvent[];
  locations?: Record<string, IpLocation>;
};

const SecurityEventsFeed: React.FC<Props> = ({ events, locations }) => (
  <div>
    <PageHeading icon={`shield`}>Security Events</PageHeading>
    {events.length === 0 && (
      <EmptyState
        className="mt-8"
        heading="No security events to show"
        secondaryText="No potentially dangerous activity has occured within the last 14 days."
        icon="shield"
        buttonText="Monitor activity"
        buttonIcon="binoculars"
        action="/"
      />
    )}
    <ul className="mt-12 flex flex-col">
      {events.map((event) => (
        <SecurityEventItem
          key={event.id}
          event={event}
          location={
            event.case === `admin` && event.ipAddress
              ? locations?.[event.ipAddress]
              : undefined
          }
        />
      ))}
    </ul>
  </div>
);

export default SecurityEventsFeed;

const SecurityEventItem: React.FC<{ event: SecurityEvent; location?: IpLocation }> = ({
  event,
  location,
}) => {
  const whenItHappened = new Date(event.createdAt);
  const [explanationExpanded, setExplanationExpanded] = useState(false);

  return (
    <li className="flex group">
      <div className="flex flex-col items-end pb-12 w-20 xs:w-24 shrink-0">
        <span className="text-xs text-slate-500">
          {whenItHappened.toLocaleTimeString(`en-US`, {
            hour: `numeric`,
            minute: `numeric`,
          })}
        </span>
        <span className="text-xs xs:text-sm text-slate-600 font-medium">
          {whenItHappened.toLocaleDateString(`en-US`, { dateStyle: `medium` })}
        </span>
      </div>
      <div className="ml-4 pl-4 pb-12 group-last:pb-0 border-l border-slate-300 flex flex-col items-start">
        <div className="mb-2 flex flex-col md+:flex-row items-start md+:items-center gap-1.5 md+:gap-0">
          <div className="flex items-center gap-1.5">
            <SeverityIndicator severity={event.severity} />
            <span
              className={cx(`rounded-full text-xs font-medium px-2 py-0.5`, {
                'bg-violet-100 text-violet-700': event.case === `admin`,
                'bg-fuchsia-100 text-fuchsia-700': event.case === `child`,
              })}
            >
              {event.case === `admin` ? `Parent website` : `Mac app`}
            </span>
          </div>
          {event.case === `child` && (
            <span className="md+:ml-1.5 text-xs xs:text-sm text-slate-500">
              <Link
                to={`/children/${event.childId}`}
                className="font-medium text-slate-700 hover:underline"
              >
                {event.childName}
              </Link>
              {` `}
              on{` `}
              <Link
                to={`/devices/${event.deviceId}`}
                className="font-medium text-slate-700 hover:underline"
              >
                {event.deviceName}
              </Link>
            </span>
          )}
          {location?.city && (
            <>
              <span className="md+:ml-1.5 text-xs xs:text-sm text-slate-500 mt-1 md+:mt-0">
                from {location.city}, {location.region}, {location.countryCode}
              </span>
              <span className="text-sm mx-1 text-slate-400 hidden md+:block">•</span>
            </>
          )}
          {event.case === `admin` && event.ipAddress && (
            <Link
              to={`https://whatismyipaddress.com/ip/${event.ipAddress}`}
              className={cx(
                `text-violet-600 text-sm font-medium underline mt-1 md+:mt-0`,
                !location?.city && `md+:ml-2`,
              )}
            >
              {event.ipAddress}
            </Link>
          )}
        </div>
        <h3 className="xs:text-lg font-medium">{event.event}</h3>
        {event.detail && (
          <p className="text-slate-600 text-sm xs:text-base">{event.detail}</p>
        )}
        <button
          className="flex border border-slate-500 rounded-full items-center py-1 px-2 gap-2 mt-2 hover:bg-slate-100 transition-colors duration-200 select-none"
          onClick={() => setExplanationExpanded(!explanationExpanded)}
        >
          <span className="text-xs text-slate-800 font-medium">Explanation</span>
          <ChevronRightIcon
            className={cx(
              `w-3.5 text-slate-500 transition-transform duration-200`,
              explanationExpanded && `rotate-90`,
            )}
            strokeWidth={2.5}
          />
        </button>
        <p
          className={cx(
            `max-w-xl mt-2 text-xs xs:text-sm text-slate-600 transition-all duration-300`,
            explanationExpanded ? `h-28 lg:h-20 opacity-100` : `h-0 opacity-0 blur-sm`,
          )}
        >
          {event.explanation}
        </p>
      </div>
    </li>
  );
};

const SeverityIndicator: React.FC<{ severity: SecurityEventSeverity }> = ({
  severity,
}) => (
  <span
    className={cx(`w-2.5 h-2.5 rounded-full`, {
      'bg-red-500': severity === `recommended`,
      'bg-yellow-500': severity === `medium`,
      'bg-slate-300': severity === `all`,
    })}
    title={
      severity === `recommended`
        ? `High priority`
        : severity === `medium`
          ? `Medium priority`
          : `Low priority`
    }
  />
);
