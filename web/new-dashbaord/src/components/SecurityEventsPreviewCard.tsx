import React, { useState } from 'react';
import cx from 'clsx';
import type { SecurityEvent } from '#/lib/mock-data';
import { Badge } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import RightColumnCard from './RightColumnCard';

interface Props {
  allSecurityEvents: Array<SecurityEvent>;
}

const getSecurityEventKey = (event: SecurityEvent): string => {
  const source =
    event.type === 'mac-app'
      ? `${event.personName}-${event.deviceName}`
      : event.ipAddress;

  return `${event.type}-${event.title}-${event.time}-${event.date}-${source}`;
};

const SecurityEventsPreviewCard: React.FC<Props> = ({ allSecurityEvents }) => {
  return (
    <RightColumnCard
      title="Recent Security Events"
      links={[
        {
          text: 'View all',
          href: '#todo',
          icon: ArrowRightIcon,
          iconPosition: 'right',
          variant: 'ghost',
        },
      ]}
    >
      <div className="bg-white border border-stone-200 rounded-xl p-3 flex flex-col shadow shadow-stone-300/30">
        {allSecurityEvents.slice(0, 4).map((e) => (
          <SecurityEventRow key={getSecurityEventKey(e)} securityEvent={e} />
        ))}
      </div>
    </RightColumnCard>
  );
};

export default SecurityEventsPreviewCard;

type SecurityEventProps = {
  securityEvent: SecurityEvent;
};

const SecurityEventRow: React.FC<SecurityEventProps> = ({ securityEvent: e }) => {
  const [showExplanation, setShowExplanation] = useState(false);

  return (
    <div
      className="flex flex-col border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer"
      onClick={() => setShowExplanation(!showExplanation)}
    >
      <div className="flex items-center justify-between mb-1.5">
        <span className="text-xs text-stone-600">
          {e.time} • {e.date}
        </span>
        <div
          className={cx('w-2 h-2 rounded-full mr-1', {
            'bg-red-500': e.severity === 'high',
            'bg-yellow-500': e.severity === 'medium',
            'bg-stone-200': e.severity === 'low',
          })}
        />
      </div>
      <div className="flex items-center gap-1.5">
        <Badge size="xsmall">
          {e.type === 'mac-app' ? 'Mac App' : 'Admin Dashboard'}
        </Badge>
        {e.type === 'mac-app' && (
          <span
            className="min-w-0 truncate text-xs text-stone-600"
            title={`${e.personName} on ${e.deviceName}`}
          >
            <a className="hover:text-stone-900 hover:underline" href="#todo">
              {e.personName}
            </a>{' '}
            on{' '}
            <a className="hover:text-stone-900 hover:underline" href="#todo">
              {e.deviceName}
            </a>
          </span>
        )}
        {e.type === 'admin-dashbaord' && (
          <a
            className="text-xs text-stone-600 hover:text-stone-900 hover:underline"
            href={`https://whatismyipaddress.com/ip/${e.ipAddress}`}
          >
            {e.ipAddress}
          </a>
        )}
      </div>
      <span className="text-sm text-stone-900 mt-1">{e.title}</span>
      {e.subtitle && <span className="text-xs text-stone-500">{e.subtitle}</span>}
      <p
        className={cx(
          'overflow-hidden text-xs text-stone-600 transition-[height,margin,opacity] duration-150',
          showExplanation ? 'mt-2 opacity-100 h-auto' : 'mt-0 opacity-0 h-0',
        )}
      >
        {e.explanation}
      </p>
    </div>
  );
};
