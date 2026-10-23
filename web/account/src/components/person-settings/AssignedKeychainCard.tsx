import { Button, DropdownMenu, DropdownMenuItem, HStack, Text } from '@gertrude/ui';
import { useNavigate } from '@tanstack/react-router';
import { EllipsisIcon, PencilIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Keychain, Schedule } from '#/components/types';
import ScheduleButton from './ScheduleButton';
import KeychainCard from '#/components/keychains/KeychainCard';
import { formatSchedule } from '#/components/utils';

interface Props extends Pick<
  Keychain,
  `id` | `name` | `description` | `numKeys` | `isPublic`
> {
  onRemove: () => void;
  schedule?: Schedule;
  setSchedule: (schedule?: Schedule) => void;
  showSchedule?: boolean;
}

const AssignedKeychainCard: React.FC<Props> = ({
  id,
  isPublic,
  name,
  description,
  numKeys,
  onRemove,
  schedule,
  setSchedule,
  showSchedule = true,
}) => {
  const navigate = useNavigate();

  return (
    <KeychainCard
      isPublic={isPublic}
      name={name}
      description={description}
      numKeys={numKeys}
      details={
        schedule && (
          <Text variant="captionStrong" className="mt-1">
            {formatSchedule(schedule)}
          </Text>
        )
      }
      actions={
        <HStack gap={2}>
          {showSchedule && (
            <ScheduleButton schedule={schedule} setSchedule={setSchedule} />
          )}
          <DropdownMenu
            trigger={
              <Button type="button" onClick={() => {}} size="small" icon={EllipsisIcon} />
            }
          >
            <DropdownMenuItem
              title="Edit"
              icon={PencilIcon}
              onSelect={() =>
                void navigate({
                  to: `/keychains/$keychainId`,
                  params: { keychainId: id },
                })
              }
            />
            <DropdownMenuItem
              title="Remove"
              icon={TrashIcon}
              onSelect={onRemove}
              destructive
            />
          </DropdownMenu>
        </HStack>
      }
    />
  );
};

export default AssignedKeychainCard;
