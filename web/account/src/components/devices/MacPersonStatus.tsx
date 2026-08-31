import { Badge, Card, HStack, Text, VStack } from '@gertrude/ui';
import { relativeTime } from '@shared/datetime';
import { Link } from '@tanstack/react-router';
import {
  ChevronRightIcon,
  CirclePauseIcon,
  Clock3Icon,
  type LucideIcon,
  MoonIcon,
  ShieldAlertIcon,
  ShieldCheckIcon,
  ShieldMinusIcon,
  WifiOffIcon,
} from 'lucide-react';
import React from 'react';
import type { ChildComputerStatus, MacDeviceDetails } from '#/components/devices/types';

type StatusDescription = {
  label: string;
  detail?: string;
  color: `green` | `red` | `yellow` | `violet` | `neutral`;
  icon: LucideIcon;
};

const statusDescription = (status: ChildComputerStatus): StatusDescription => {
  switch (status.case) {
    case `filterOn`:
      return { label: `Filter on`, color: `green`, icon: ShieldCheckIcon };
    case `filterOff`:
      return { label: `Filter off`, color: `red`, icon: ShieldAlertIcon };
    case `unfiltered`:
      return { label: `Filtering disabled`, color: `yellow`, icon: ShieldMinusIcon };
    case `offline`:
      return { label: `Offline`, color: `neutral`, icon: WifiOffIcon };
    case `filterSuspended`:
      return {
        label: `Filter suspended`,
        detail: status.resuming ? `Resumes ${relativeTime(status.resuming)}` : undefined,
        color: `yellow`,
        icon: CirclePauseIcon,
      };
    case `downtime`:
      return {
        label: `In downtime`,
        detail: status.ending ? `Ends ${relativeTime(status.ending)}` : undefined,
        color: `violet`,
        icon: MoonIcon,
      };
    case `downtimePaused`:
      return {
        label: `Downtime paused`,
        detail: status.resuming ? `Resumes ${relativeTime(status.resuming)}` : undefined,
        color: `yellow`,
        icon: Clock3Icon,
      };
  }
};

interface Props {
  person: MacDeviceDetails[`people`][number];
}

const MacPersonStatus: React.FC<Props> = ({ person }) => {
  const status = statusDescription(person.status);

  return (
    <Link
      to="/people/$personId/mac-settings"
      params={{ personId: person.id }}
      className="group block rounded-xl outline-none focus-visible:ring-2 focus-visible:ring-violet-300"
    >
      <Card
        interactive
        padding={3}
        className="flex items-center justify-between gap-3 group-focus-visible:border-violet-300"
      >
        <Text variant="bodyStrong" truncate className="min-w-0">
          {person.name}
        </Text>
        <HStack gap={2} className="shrink-0">
          <VStack gap={1} align="end">
            <Badge size="small" color={status.color} icon={status.icon}>
              {status.label}
            </Badge>
            {status.detail && <Text variant="captionMuted">{status.detail}</Text>}
          </VStack>
          <ChevronRightIcon
            className="h-4 w-4 text-stone-400 transition-colors group-hover:text-stone-600"
            aria-hidden="true"
          />
        </HStack>
      </Card>
    </Link>
  );
};

export default MacPersonStatus;
