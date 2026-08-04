import {
  Badge,
  Button,
  Card,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  Text,
  VStack,
  inflect,
} from '@gertrude/ui';
import { EllipsisIcon, PencilIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Schedule } from '#/components/types';
import ScheduleButton from './ScheduleButton';
import { formatSchedule } from '#/components/utils';

type Props = {
  name: string;
  description?: string;
  numKeys: number;
  isPublic: boolean;
  onRemove: () => void;
  schedule?: Schedule;
  setSchedule: (schedule?: Schedule) => void;
  showSchedule?: boolean;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  description,
  numKeys,
  onRemove,
  schedule,
  setSchedule,
  showSchedule = true,
}) => (
  <Card padding={3} className="flex flex-col">
    <VStack gap={0.5} className="flex-grow">
      <HStack gap={2}>
        <Text variant="bodyLargeStrong">{name}</Text>
        {isPublic && <Badge size="small">Public</Badge>}
      </HStack>
      {description && <Text variant="captionSubtle">{description}</Text>}
      {schedule && (
        <Text variant="captionStrong" className="mt-1">
          {formatSchedule(schedule)}
        </Text>
      )}
    </VStack>
    <HStack justify="between" gap={3} className="mt-3">
      <Text variant="captionMuted">
        {numKeys} {inflect(`key`, numKeys)}
      </Text>
      <HStack gap={2}>
        {showSchedule && <ScheduleButton schedule={schedule} setSchedule={setSchedule} />}
        <DropdownMenu
          trigger={
            <Button type="button" onClick={() => {}} size="small" icon={EllipsisIcon} />
          }
        >
          <DropdownMenuItem
            title="Edit"
            icon={PencilIcon}
            disabled
            disabledTooltip="Coming Soon"
          />
          <DropdownMenuItem
            title="Remove"
            icon={TrashIcon}
            onSelect={onRemove}
            destructive
          />
        </DropdownMenu>
      </HStack>
    </HStack>
  </Card>
);

export default KeychainCard;
