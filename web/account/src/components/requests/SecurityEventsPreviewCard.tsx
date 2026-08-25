import { Badge, Button, Card, HStack, Skeleton, Text, VStack } from '@gertrude/ui';
import { formatTime } from '@shared/datetime';
import cx from 'clsx';
import {
  ArrowRightIcon,
  ChevronDownIcon,
  LaptopIcon,
  RefreshCwIcon,
  ShieldCheckIcon,
  UserIcon,
} from 'lucide-react';
import React from 'react';
import type { LoadableState, SecurityEvent } from '#/components/types';
import RightColumnCard from './RightColumnCard';

interface Props {
  state: LoadableState<SecurityEvent[]>;
  onRefresh: () => void;
  refreshing?: boolean;
  viewAllHref?: string;
}

const SecurityEventsPreviewCard: React.FC<Props> = ({
  state,
  onRefresh,
  refreshing,
  viewAllHref = `#`,
}) => {
  if (state.status === `success` && state.data.length === 0) {
    return (
      <RightColumnCard
        variant="empty"
        icon={ShieldCheckIcon}
        text="No recent security events"
        onRefresh={onRefresh}
        refreshing={refreshing}
      />
    );
  }

  return (
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
      {state.status === `loading` ? (
        <Card padding={3}>
          <span role="status" className="sr-only">
            Loading security events
          </span>
          <VStack gap={3}>
            {[0, 1, 2].map((index) => (
              <VStack key={index} gap={1.5}>
                <Skeleton className="h-3 w-24" />
                <Skeleton className="h-4 w-full" />
              </VStack>
            ))}
          </VStack>
        </Card>
      ) : state.status === `error` ? (
        <Card padding={3}>
          <VStack gap={3} align="start">
            <Text variant="captionMuted">{state.message}</Text>
            <Button
              type="button"
              size="small"
              icon={RefreshCwIcon}
              onClick={state.onRetry}
            >
              Try again
            </Button>
          </VStack>
        </Card>
      ) : (
        <Card padding={3}>
          <VStack>
            {state.data.slice(0, 4).map((event) => (
              <SecurityEventRow key={event.id} securityEvent={event} />
            ))}
          </VStack>
        </Card>
      )}
    </RightColumnCard>
  );
};

export default SecurityEventsPreviewCard;

interface SecurityEventRowProps {
  securityEvent: SecurityEvent;
}

const SecurityEventRow: React.FC<SecurityEventRowProps> = ({ securityEvent }) => {
  const [showExplanation, setShowExplanation] = React.useState(false);
  const explanationId = React.useId();

  return (
    <VStack className="border-b border-stone-200/80 py-3 first:pt-0 last:border-b-0 last:pb-0">
      <HStack justify="between" className="mb-1.5">
        <Text variant="captionSubtle">
          {formatTime(securityEvent.createdAt)} •{` `}
          {securityEvent.createdAt.toLocaleDateString(`en-US`, {
            month: `short`,
            day: `numeric`,
          })}
        </Text>
        <SeverityDot severity={securityEvent.severity} />
      </HStack>
      <HStack gap={1.5}>
        <Badge
          size="xsmall"
          color={securityEvent.type === `mac-app` ? `blue` : `violet`}
          icon={securityEvent.type === `mac-app` ? LaptopIcon : UserIcon}
        >
          {securityEvent.type === `mac-app` ? `Mac app` : `Gertrude Account`}
        </Badge>
        {securityEvent.type === `mac-app` ? (
          <Text
            variant="captionSubtle"
            truncate
            className="min-w-0"
            title={`${securityEvent.personName} on ${securityEvent.deviceName}`}
          >
            <a
              className="hover:text-stone-900 hover:underline"
              href={`/people/${securityEvent.personId}`}
            >
              {securityEvent.personName}
            </a>
            {` on `}
            <a
              className="hover:text-stone-900 hover:underline"
              href={`/people/${securityEvent.personId}/mac-settings`}
            >
              {securityEvent.deviceName}
            </a>
          </Text>
        ) : (
          securityEvent.ipAddress && (
            <Text
              as="a"
              variant="captionSubtle"
              className="hover:text-stone-900 hover:underline"
              href={`https://whatismyipaddress.com/ip/${securityEvent.ipAddress}`}
              target="_blank"
              rel="noreferrer"
            >
              {securityEvent.ipAddress}
            </Text>
          )
        )}
      </HStack>
      <Text variant="bodyStrong" className="mt-1">
        {securityEvent.title}
      </Text>
      {securityEvent.detail && <Text variant="captionMuted">{securityEvent.detail}</Text>}
      <button
        type="button"
        aria-expanded={showExplanation}
        aria-controls={explanationId}
        onClick={() => setShowExplanation((current) => !current)}
        className="mt-1 -ml-1 inline-flex w-fit cursor-pointer items-center gap-0.5 rounded px-1 py-0.5 text-xs font-medium text-stone-500 outline-none hover:bg-stone-100 hover:text-stone-800 focus-visible:ring-2 focus-visible:ring-violet-300/80"
      >
        Explanation
        <ChevronDownIcon
          className={cx(
            `h-3 w-3 transition-transform duration-150`,
            showExplanation && `rotate-180`,
          )}
        />
      </button>
      {showExplanation && (
        <Text as="p" id={explanationId} variant="caption" className="mt-1.5">
          {securityEvent.explanation}
        </Text>
      )}
    </VStack>
  );
};

const SeverityDot: React.FC<{ severity: SecurityEvent[`severity`] }> = ({ severity }) => (
  <span
    className={cx(`mr-1 h-2 w-2 shrink-0 rounded-full`, {
      'bg-red-500': severity === `high`,
      'bg-amber-400': severity === `medium`,
      'bg-stone-300': severity === `low`,
    })}
  />
);
