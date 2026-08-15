import {
  Badge,
  Button,
  Card,
  Divider,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  Text,
  VStack,
} from '@gertrude/ui';
import { EllipsisIcon, TrashIcon, TriangleAlertIcon, XIcon } from 'lucide-react';
import React from 'react';
import type { Schedule } from '#/components/types';
import ScheduleButton, { ScheduleEditor } from './ScheduleButton';
import { formatSchedule } from '#/components/utils';

interface Props {
  app: {
    name: string;
    appIconUrl?: string;
    schedule?: Schedule;
  };
  onRemove?: () => void;
  setSchedule?: (schedule?: Schedule) => void;
  sourceLabel?: string;
  ineffective?: boolean;
  statusLabel?: string;
}

const ConfiguredAppRow: React.FC<Props> = ({
  app,
  onRemove,
  setSchedule,
  sourceLabel,
  ineffective = false,
  statusLabel,
}) => (
  <Card padding={3} className="flex items-center justify-between gap-2">
    <HStack gap={4}>
      <div className="shrink-0">
        {app.appIconUrl ? (
          <div className="h-11 w-11 shrink-0 -m-1.5">
            <img src={app.appIconUrl} alt="" className="w-full h-full" />
          </div>
        ) : (
          <HStack
            justify="center"
            className="h-9 w-9 rounded-lg bg-stone-200 text-lg font-semibold text-stone-500 -m-0.5"
          >
            {app.name.slice(0, 1).toUpperCase()}
          </HStack>
        )}
      </div>
      <VStack gap={0.5}>
        <Text variant="bodyStrong">{app.name}</Text>
        <HStack gap={2} wrap>
          {app.schedule && (
            <Text variant="captionSubtle">{formatSchedule(app.schedule)}</Text>
          )}
          {ineffective ? (
            <Badge size="small" color="yellow" icon={TriangleAlertIcon}>
              Blocked — no effect
            </Badge>
          ) : statusLabel ? (
            <Badge size="small" color="green">
              {statusLabel}
            </Badge>
          ) : null}
          {sourceLabel && <Badge size="small">From {sourceLabel}</Badge>}
        </HStack>
      </VStack>
    </HStack>
    {setSchedule && onRemove ? (
      <>
        <HStack gap={2} hideBelow="sm">
          <ScheduleButton schedule={app.schedule} setSchedule={setSchedule} />
          <Button
            type="button"
            ariaLabel={`Remove ${app.name}`}
            onClick={onRemove}
            icon={XIcon}
            size="small"
            variant="ghost"
          />
        </HStack>
        <div className="sm:hidden">
          <DropdownMenu
            contentClassName="w-82"
            trigger={
              <Button
                type="button"
                ariaLabel={`More actions for ${app.name}`}
                onClick={() => {}}
                icon={EllipsisIcon}
                size="small"
              />
            }
          >
            <ScheduleEditor schedule={app.schedule} setSchedule={setSchedule} />
            <div className="mx-1 pt-1">
              <Divider />
              <DropdownMenuItem
                title="Remove App"
                icon={TrashIcon}
                onSelect={onRemove}
                destructive
              />
            </div>
          </DropdownMenu>
        </div>
      </>
    ) : onRemove ? (
      <Button
        type="button"
        ariaLabel={`Remove ${app.name}`}
        onClick={onRemove}
        icon={XIcon}
        size="small"
        variant="ghost"
      />
    ) : null}
  </Card>
);

export default ConfiguredAppRow;
