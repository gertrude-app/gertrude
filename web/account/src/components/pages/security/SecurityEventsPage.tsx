import {
  Badge,
  Button,
  Card,
  DropdownMenu,
  DropdownMenuCheckboxItem,
  EmptyState,
  HStack,
  PageHeading,
  Skeleton,
  Text,
  VStack,
} from '@gertrude/ui';
import { formatDate, formatTime } from '@shared/datetime';
import { Link } from '@tanstack/react-router';
import cx from 'clsx';
import {
  ChevronDownIcon,
  CircleAlertIcon,
  LaptopIcon,
  RefreshCwIcon,
  ShieldCheckIcon,
  ShieldIcon,
  UserIcon,
} from 'lucide-react';
import React from 'react';
import type { LoadableState, SecurityEvent } from '#/components/types';
import type {
  IpLocation,
  SecurityEventFilters,
  SecurityEventSeverity,
  SecurityEventSource,
} from '#/lib/securityEvents';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import { filterSecurityEvents } from '#/lib/securityEvents';

export type SecurityEventsState = LoadableState<SecurityEvent[]>;

interface Props {
  state: SecurityEventsState;
  filters: SecurityEventFilters;
  locations?: Record<string, IpLocation>;
  refreshing?: boolean;
  onRefresh: () => void;
  onFiltersChange: (filters: SecurityEventFilters) => void;
  now?: Date;
}

const severityOptions: Array<{
  value: SecurityEventSeverity;
  label: string;
}> = [
  { value: `high`, label: `High` },
  { value: `medium`, label: `Medium` },
  { value: `low`, label: `Low` },
];

const sourceOptions: Array<{
  value: SecurityEventSource;
  label: string;
}> = [
  { value: `mac-app`, label: `Mac app` },
  { value: `account`, label: `Gertrude Account` },
];

const severityLabels: Record<SecurityEventSeverity, string> = {
  high: `High priority`,
  medium: `Medium priority`,
  low: `Low priority`,
};

const toggleValue = <Value extends string>(values: Value[], value: Value): Value[] =>
  values.includes(value)
    ? values.filter((current) => current !== value)
    : [...values, value];

interface MultiSelectFilterProps<Value extends string> {
  label: string;
  values: Value[];
  options: Array<{ value: Value; label: string }>;
  onChange: (values: Value[]) => void;
}

function MultiSelectFilter<Value extends string>({
  label,
  values,
  options,
  onChange,
}: MultiSelectFilterProps<Value>): React.ReactElement {
  const selectionLabel =
    values.length === 0
      ? `All`
      : values.length === 1
        ? options.find((option) => option.value === values[0])?.label
        : `${values.length} selected`;

  return (
    <DropdownMenu
      contentClassName="w-52"
      trigger={
        <Button
          type="button"
          size="small"
          icon={ChevronDownIcon}
          iconPosition="right"
          onClick={() => {}}
        >
          {label}: {selectionLabel}
        </Button>
      }
    >
      {options.map((option) => (
        <DropdownMenuCheckboxItem
          key={option.value}
          title={label === `Priority` ? `${option.label} priority` : option.label}
          checked={values.includes(option.value)}
          onCheckedChange={() => onChange(toggleValue(values, option.value))}
        />
      ))}
    </DropdownMenu>
  );
}

interface FilterToolbarProps {
  filters: SecurityEventFilters;
  onFiltersChange: (filters: SecurityEventFilters) => void;
}

const FilterToolbar: React.FC<FilterToolbarProps> = ({ filters, onFiltersChange }) => {
  const hasFilters = filters.severities.length > 0 || filters.sources.length > 0;

  return (
    <HStack wrap gap={2}>
      <MultiSelectFilter
        label="Priority"
        values={filters.severities}
        options={severityOptions}
        onChange={(severities) => onFiltersChange({ ...filters, severities })}
      />
      <MultiSelectFilter
        label="Source"
        values={filters.sources}
        options={sourceOptions}
        onChange={(sources) => onFiltersChange({ ...filters, sources })}
      />
      {hasFilters && (
        <Button
          type="button"
          size="small"
          variant="ghost"
          onClick={() => onFiltersChange({ severities: [], sources: [] })}
        >
          Clear filters
        </Button>
      )}
    </HStack>
  );
};

const SecurityEventsLoadingState: React.FC = () => (
  <VStack gap={5}>
    <span role="status" className="sr-only">
      Loading security events
    </span>
    <HStack gap={2} wrap>
      <Skeleton className="h-7 w-28" radius="medium" />
      <Skeleton className="h-7 w-28" radius="medium" />
    </HStack>
    <CardContainer className="flex flex-col gap-4">
      {[0, 1].map((group) => (
        <Card key={group} padding={4}>
          <VStack gap={3}>
            <Skeleton className="h-4 w-28" />
            <Skeleton className="h-4 w-48" />
            <Skeleton className="h-5 w-72 max-w-full" />
            <Skeleton className="h-3 w-32" />
          </VStack>
        </Card>
      ))}
    </CardContainer>
  </VStack>
);

interface DateGroup {
  key: string;
  label: string;
  events: SecurityEvent[];
}

function groupByDate(events: SecurityEvent[], now: Date): DateGroup[] {
  const groups = new Map<string, SecurityEvent[]>();
  for (const event of events) {
    const key = [
      event.createdAt.getFullYear(),
      event.createdAt.getMonth(),
      event.createdAt.getDate(),
    ].join(`-`);
    const group = groups.get(key) ?? [];
    group.push(event);
    groups.set(key, group);
  }

  return Array.from(groups).flatMap(([key, groupEvents]) => {
    const firstEvent = groupEvents[0];
    return firstEvent
      ? [{ key, label: dateGroupLabel(firstEvent.createdAt, now), events: groupEvents }]
      : [];
  });
}

function dateGroupLabel(date: Date, now: Date): string {
  const dayNumber = (value: Date): number =>
    Date.UTC(value.getFullYear(), value.getMonth(), value.getDate()) / 86_400_000;
  const difference = dayNumber(now) - dayNumber(date);
  if (difference === 0) return `Today`;
  if (difference === 1) return `Yesterday`;
  return formatDate(date, `long`);
}

interface SecurityEventTimelineProps {
  events: SecurityEvent[];
  locations: Record<string, IpLocation>;
  now: Date;
}

const SecurityEventTimeline: React.FC<SecurityEventTimelineProps> = ({
  events,
  locations,
  now,
}) => (
  <CardContainer className="flex flex-col gap-4">
    {groupByDate(events, now).map((group) => (
      <Card
        as="section"
        key={group.key}
        padding={{ default: 3, '@xl/main': 4 }}
        aria-labelledby={`security-date-${group.key}`}
      >
        <Text
          as="h2"
          id={`security-date-${group.key}`}
          variant="label"
          className="mb-3 px-1 text-sm !text-stone-700"
        >
          {group.label}
        </Text>
        <ol className="ml-2">
          {group.events.map((event, index) => (
            <SecurityEventRow
              key={event.id}
              event={event}
              first={index === 0}
              last={index === group.events.length - 1}
              location={
                event.type === `account` && event.ipAddress
                  ? locations[event.ipAddress]
                  : undefined
              }
            />
          ))}
        </ol>
      </Card>
    ))}
  </CardContainer>
);

interface SecurityEventRowProps {
  event: SecurityEvent;
  location?: IpLocation;
  first: boolean;
  last: boolean;
}

const SecurityEventRow: React.FC<SecurityEventRowProps> = ({
  event,
  location,
  first,
  last,
}) => {
  const [expanded, setExpanded] = React.useState(false);
  const explanationId = React.useId();

  return (
    <li className={cx(`relative pl-5`, !last && `pb-5`)}>
      <span
        aria-hidden="true"
        className="absolute left-0 w-0.5 bg-stone-200"
        style={{
          top: first ? 9 : 0,
          bottom: last ? `calc(100% - 9px)` : 0,
        }}
      />
      <span className="absolute top-1 -left-1 z-10 rounded-full bg-white ring-4 ring-white">
        <SeverityDot severity={event.severity} />
      </span>
      <VStack gap={1.5} className={cx(!last && `border-b border-stone-200/70 pb-3`)}>
        <div className="flex flex-col gap-1 @lg/main:flex-row @lg/main:items-start @lg/main:justify-between">
          <HStack wrap gap={1.5}>
            <Badge
              size="xsmall"
              color={event.type === `mac-app` ? `blue` : `violet`}
              icon={event.type === `mac-app` ? LaptopIcon : UserIcon}
            >
              {event.type === `mac-app` ? `Mac app` : `Gertrude Account`}
            </Badge>
            <EventContext event={event} location={location} />
          </HStack>
          <Text
            as="time"
            dateTime={event.createdAt.toISOString()}
            variant="captionMuted"
            className="shrink-0"
          >
            {formatTime(event.createdAt)}
          </Text>
        </div>
        <VStack gap={0.5}>
          <Text as="h3" variant="bodyLargeStrong">
            {event.title}
          </Text>
          {event.detail && (
            <Text as="p" variant="bodySubtle">
              {event.detail}
            </Text>
          )}
        </VStack>
        <div>
          <button
            type="button"
            aria-expanded={expanded}
            aria-controls={explanationId}
            onClick={() => setExpanded((current) => !current)}
            className="-ml-1.5 inline-flex cursor-pointer items-center gap-1 rounded-md px-1.5 py-1 text-xs font-medium text-stone-600 outline-none transition-colors hover:bg-stone-100 hover:text-stone-900 focus-visible:ring-2 focus-visible:ring-violet-300/80"
          >
            Explanation
            <ChevronDownIcon
              aria-hidden="true"
              className={cx(
                `h-3.5 w-3.5 transition-transform duration-150`,
                expanded && `rotate-180`,
              )}
            />
          </button>
          {expanded && (
            <Text
              as="p"
              id={explanationId}
              variant="proseSubtle"
              className="mt-1 max-w-3xl"
            >
              {event.explanation}
            </Text>
          )}
        </div>
      </VStack>
    </li>
  );
};

interface EventContextProps {
  event: SecurityEvent;
  location?: IpLocation;
}

const EventContext: React.FC<EventContextProps> = ({ event, location }) => {
  if (event.type === `mac-app`) {
    return (
      <Text variant="captionSubtle" className="min-w-0">
        <Link
          to="/people/$personId"
          params={{ personId: event.personId }}
          className="font-medium text-stone-700 hover:text-stone-950 hover:underline"
        >
          {event.personName}
        </Link>
        {` on `}
        <Link
          to="/people/$personId/mac-settings"
          params={{ personId: event.personId }}
          className="font-medium text-stone-700 hover:text-stone-950 hover:underline"
        >
          {event.deviceName}
        </Link>
      </Text>
    );
  }

  if (!event.ipAddress) return null;

  return (
    <Text variant="captionSubtle">
      {location &&
        `from ${location.city}, ${location.region}, ${location.countryCode} · `}
      <a
        href={`https://whatismyipaddress.com/ip/${event.ipAddress}`}
        target="_blank"
        rel="noreferrer"
        className="font-medium text-violet-700 hover:text-violet-900 hover:underline"
      >
        {event.ipAddress}
      </a>
    </Text>
  );
};

interface SeverityDotProps {
  severity: SecurityEventSeverity;
  size?: `small` | `medium`;
}

const SeverityDot: React.FC<SeverityDotProps> = ({ severity, size = `medium` }) => (
  <span
    role="img"
    aria-label={severityLabels[severity]}
    title={severityLabels[severity]}
    className={cx(
      `block shrink-0 rounded-full`,
      size === `small` ? `h-2 w-2` : `h-2.5 w-2.5`,
      {
        'bg-red-500': severity === `high`,
        'bg-amber-400': severity === `medium`,
        'bg-stone-300': severity === `low`,
      },
    )}
  />
);

const SecurityEventsPage: React.FC<Props> = ({
  state,
  filters,
  locations = {},
  refreshing,
  onRefresh,
  onFiltersChange,
  now = new Date(),
}) => {
  const filteredEvents =
    state.status === `success` ? filterSecurityEvents(state.data, filters) : [];

  return (
    <DashboardPage
      heading={
        <PageHeading
          title="Security Events"
          subtitle="Review important activity from your Macs and Gertrude Account. Events are kept for 14 days."
          buttons={[{ text: `Refresh`, icon: RefreshCwIcon, onClick: onRefresh }]}
        />
      }
    >
      {state.status === `loading` ? (
        <SecurityEventsLoadingState />
      ) : state.status === `error` ? (
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load security events"
            description={state.message}
            button={{
              text: `Try again`,
              type: `button`,
              onClick: state.onRetry,
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      ) : (
        <VStack gap={6}>
          <FilterToolbar filters={filters} onFiltersChange={onFiltersChange} />
          {state.data.length === 0 ? (
            <EmptyState
              icon={ShieldCheckIcon}
              title="No security events"
              description="No noteworthy security activity has been recorded in the last 14 days."
              button={{
                text: `Refresh`,
                type: `button`,
                onClick: onRefresh,
                icon: RefreshCwIcon,
                loading: refreshing,
              }}
              className="bg-white"
            />
          ) : filteredEvents.length === 0 ? (
            <EmptyState
              icon={ShieldIcon}
              title="No events match these filters"
              description="Choose different priorities or sources to see more security events."
              button={{
                text: `Clear filters`,
                type: `button`,
                onClick: () => onFiltersChange({ severities: [], sources: [] }),
              }}
              className="bg-white"
            />
          ) : (
            <SecurityEventTimeline
              events={filteredEvents}
              locations={locations}
              now={now}
            />
          )}
        </VStack>
      )}
    </DashboardPage>
  );
};

export default SecurityEventsPage;
