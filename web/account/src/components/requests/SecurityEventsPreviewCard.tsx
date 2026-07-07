import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
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
    <Card padding={3}>
      <VStack>
        {securityEvents.slice(0, 4).map((event) => (
          <SecurityEventRow key={event.id} securityEvent={event} />
        ))}
      </VStack>
    </Card>
  </RightColumnCard>
);

export default SecurityEventsPreviewCard;

type SecurityEventProps = {
  securityEvent: SecurityEvent;
};

const SecurityEventRow: React.FC<SecurityEventProps> = ({ securityEvent }) => {
  const [showExplanation, setShowExplanation] = React.useState(false);

  return (
    <VStack
      className="border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer text-left"
      onClick={() => setShowExplanation(!showExplanation)}
    >
      <HStack justify="between" className="mb-1.5">
        <Text variant="captionSubtle">
          {securityEvent.time} • {securityEvent.date}
        </Text>
        <div
          className={cx(`w-2 h-2 rounded-full mr-1`, {
            'bg-red-500': securityEvent.severity === `high`,
            'bg-yellow-500': securityEvent.severity === `medium`,
            'bg-stone-200': securityEvent.severity === `low`,
          })}
        />
      </HStack>
      <HStack gap={1.5}>
        <Badge size="xsmall">
          {securityEvent.type === `mac-app` ? `Mac App` : `Admin Dashboard`}
        </Badge>
        {securityEvent.type === `mac-app` && (
          <Text
            variant="captionSubtle"
            truncate
            className="min-w-0"
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
          </Text>
        )}
        {securityEvent.type === `admin-dashboard` && (
          <Text
            as="a"
            variant="captionSubtle"
            className="hover:text-stone-900 hover:underline"
            href={
              securityEvent.ipAddressHref ??
              `https://whatismyipaddress.com/ip/${securityEvent.ipAddress}`
            }
            onClick={(event) => event.stopPropagation()}
          >
            {securityEvent.ipAddress}
          </Text>
        )}
      </HStack>
      <Text variant="bodyStrong" className="mt-1">
        {securityEvent.title}
      </Text>
      {securityEvent.subtitle && (
        <Text variant="captionMuted">{securityEvent.subtitle}</Text>
      )}
      <Text
        as="p"
        variant="caption"
        className={cx(
          `overflow-hidden transition-[height,margin,opacity] duration-150`,
          showExplanation ? `mt-2 opacity-100 h-auto` : `mt-0 opacity-0 h-0`,
        )}
      >
        {securityEvent.explanation}
      </Text>
    </VStack>
  );
};
