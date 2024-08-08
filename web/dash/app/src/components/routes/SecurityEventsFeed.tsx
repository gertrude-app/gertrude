import cx from 'classnames';
import { EmptyState, PageHeading } from '@dash/components';
import { ChevronRightIcon } from '@heroicons/react/24/outline';
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ApiErrorMessage, Loading } from '@dash/components';
import type { SecurityEventsFeed } from '@dash/types';
import { Key, useQuery } from '../../hooks';
import Current from '../../environment';

const SecurityEventsFeed: React.FC = () => {
  const getFeed = useQuery(Key.securityEventsFeed, Current.api.securityEventsFeed);

  if (getFeed.isPending) {
    return <Loading />;
  }

  if (getFeed.isError) {
    return <ApiErrorMessage error={getFeed.error} />;
  }

  const feed = getFeed.data;
  return (
    <div>
      <PageHeading icon={`shield`}>Security Events</PageHeading>
      {feed.length === 0 && (
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
        {feed.map((event) => (
          <SecurityEvent event={event} />
        ))}
      </ul>
    </div>
  );
};

export default SecurityEventsFeed;

type Location = {
  city: string;
  region: string;
  country_code: string;
};

const SecurityEvent: React.FC<{ event: SecurityEventsFeed.Output[number] }> = ({
  event,
}) => {
  const whenItHappened = new Date(event.createdAt);
  const [explanationExpanded, setExplanationExpanded] = useState(false);
  const [where, setWhere] = useState<Location | null>(null);
  const ipAddress = event.case === `admin` ? event.ipAddress : undefined;

  useEffect(() => {
    if (ipAddress) {
      getLocation(ipAddress).then(setWhere);
    }
  }, [ipAddress]);

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
        <div className="mb-2 flex flex-col md+:flex-row items-start md+:items-center">
          <span
            className={cx(
              `rounded-full text-xs xs:text-sm font-medium w-14 flex justify-center`,
              {
                'bg-indigo-200 text-indigo-800': event.case === `admin`,
                'bg-fuchsia-200 text-fuchsia-800': event.case === `child`,
              },
            )}
          >
            {event.case}
          </span>
          {event.case === `child` && (
            <span className="ml-1.5 text-xs xs:text-sm text-slate-500">
              <Link
                to={`/children/${event.childId}`}
                className="font-medium text-slate-700 hover:underline"
              >
                {event.childName}
              </Link>
              {` `}
              on{` `}
              <Link
                to={`/computers/${event.deviceId}`}
                className="font-medium text-slate-700 hover:underline"
              >
                {event.deviceName}
              </Link>
            </span>
          )}
          {where && where.city && (
            <>
              <span className="md+:ml-1.5 text-xs xs:text-sm text-slate-500 mt-1 md+:mt-0">
                from {where.city}, {where.region}, {where.country_code}
              </span>
              <span className="text-sm mx-1 text-slate-400 hidden md+:block">•</span>
            </>
          )}
          {event.case === `admin` && event.ipAddress && (
            <Link
              to={`https://whatismyipaddress.com/ip/${event.ipAddress}`}
              className={cx(
                `text-indigo-500 text-sm font-semibold underline mt-1 md+:mt-0`,
                (!where || !where.city) && `md+:ml-2`,
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

const locationCache: Record<string, Promise<Location | null>> = {};

function getLocation(ip: string): Promise<Location | null> {
  if (!locationCache[ip]) {
    locationCache[ip] = fetch(`https://ipapi.co/${ip}/json/`)
      .then((res) => res.json())
      .catch(() => null);
  }
  return locationCache[ip];
}
