import {
  Button,
  Card,
  Divider,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  Text,
  VStack,
} from '@gertrude/ui';
import { EllipsisIcon, TrashIcon, XIcon } from 'lucide-react';
import React from 'react';
import type { ConfiguredMacApp, Schedule } from '#/components/types';
import ScheduleButton, { ScheduleEditor } from './ScheduleButton';
import { formatSchedule } from '#/components/utils';

interface Props {
  app: ConfiguredMacApp;
  onRemove: () => void;
  setSchedule?: (schedule?: Schedule) => void;
}

const ConfiguredAppRow: React.FC<Props> = ({ app, onRemove, setSchedule }) => (
  <Card padding={3} className="flex items-center justify-between gap-2">
    <HStack gap={3}>
      <div className="shrink-0">
        <img
          src={app.appIconUrl}
          alt=""
          className="w-10 h-10 absolute blur-xs opacity-50"
        />
        <img
          src={app.appIconUrl}
          alt=""
          className="w-10 h-10 shadow rounded-[11px] relative"
        />
      </div>
      <VStack>
        <Text variant="bodyStrong">{app.nameOrBundleId}</Text>
        {app.schedule && (
          <Text variant="captionSubtle" className="-mt-0.25">
            {formatSchedule(app.schedule)}
          </Text>
        )}
      </VStack>
    </HStack>
    {setSchedule ? (
      <>
        <HStack gap={2} hideBelow="sm">
          <ScheduleButton schedule={app.schedule} setSchedule={setSchedule} />
          <Button
            type="button"
            ariaLabel={`Remove ${app.nameOrBundleId}`}
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
                ariaLabel={`More actions for ${app.nameOrBundleId}`}
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
    ) : (
      <Button
        type="button"
        ariaLabel={`Remove ${app.nameOrBundleId}`}
        onClick={onRemove}
        icon={XIcon}
        size="small"
        variant="ghost"
      />
    )}
  </Card>
);

export default ConfiguredAppRow;
