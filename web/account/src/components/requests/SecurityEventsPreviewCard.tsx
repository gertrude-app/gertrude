import { Badge } from '@gertrude/ui';
import cx from 'clsx';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { SecurityEvent } from '#/components/types';
import RightColumnCard from './RightColumnCard';

interface Props {
  securityEvents: SecurityEvent[];
  viewAllHref?: string;
}

const SecurityEventsPreviewCard: React.FC<Props> = ({
  securityEvents,
  viewAllHref = `#`,
}) => (
  <RightColumnCard
    title="Recent Security Events"
    links={[
      {
        text: `View all`,
        href: viewAllHref,
        icon: ArrowRightIcon,
        iconPosition: `right`,
        variant: `ghost`,
      },
    ]}
  >
    <div className="bg-white border border-stone-200 rounded-xl p-3 flex flex-col shadow shadow-stone-300/30">
      {securityEvents.slice(0, 4).map((event) => (
        <SecurityEventRow key={event.id} securityEvent={event} />
      ))}
    </div>
  </RightColumnCard>
);

export default SecurityEventsPreviewCard;

type SecurityEventProps = {
  securityEvent: SecurityEvent;
};

const SecurityEventRow: React.FC<SecurityEventProps> = ({ securityEvent }) => {
  const [showExplanation, setShowExplanation] = React.useState(false);

  return (
    <div
      className="flex flex-col border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer text-left"
      onClick={() => setShowExplanation(!showExplanation)}
    >
      <div className="flex items-center justify-between mb-1.5">
        <span className="text-xs text-stone-600">
          {securityEvent.time} • {securityEvent.date}
        </span>
        <div
          className={cx(`w-2 h-2 rounded-full mr-1`, {
            'bg-red-500': securityEvent.severity === `high`,
            'bg-yellow-500': securityEvent.severity === `medium`,
            'bg-stone-200': securityEvent.severity === `low`,
          })}
        />
      </div>
      <div className="flex items-center gap-1.5">
        <Badge size="xsmall">
          {securityEvent.type === `mac-app` ? `Mac App` : `Admin Dashboard`}
        </Badge>
        {securityEvent.type === `mac-app` && (
          <span
            className="min-w-0 truncate text-xs text-stone-600"
            title={`${securityEvent.personName} on ${securityEvent.deviceName}`}
          >
            <a
              className="hover:text-stone-900 hover:underline"
              href={securityEvent.personHref ?? `#`}
              onClick={(event) => event.stopPropagation()}
            >
              {securityEvent.personName}
            </a>
            {` `}
            on{` `}
            <a
              className="hover:text-stone-900 hover:underline"
              href={securityEvent.deviceHref ?? `#`}
              onClick={(event) => event.stopPropagation()}
            >
              {securityEvent.deviceName}
            </a>
          </span>
        )}
        {securityEvent.type === `admin-dashboard` && (
          <a
            className="text-xs text-stone-600 hover:text-stone-900 hover:underline"
            href={
              securityEvent.ipAddressHref ??
              `https://whatismyipaddress.com/ip/${securityEvent.ipAddress}`
            }
            onClick={(event) => event.stopPropagation()}
          >
            {securityEvent.ipAddress}
          </a>
        )}
      </div>
      <span className="text-sm text-stone-900 mt-1">{securityEvent.title}</span>
      {securityEvent.subtitle && (
        <span className="text-xs text-stone-500">{securityEvent.subtitle}</span>
      )}
      <p
        className={cx(
          `overflow-hidden text-xs text-stone-600 transition-[height,margin,opacity] duration-150`,
          showExplanation ? `mt-2 opacity-100 h-auto` : `mt-0 opacity-0 h-0`,
        )}
      >
        {securityEvent.explanation}
      </p>
    </div>
  );
};
