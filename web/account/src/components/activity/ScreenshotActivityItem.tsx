import { Button, Card, Divider, HStack, Text, Tooltip } from '@gertrude/ui';
import { formatTime } from '@shared/datetime';
import { FlagIcon, TrashIcon } from 'lucide-react';
import React from 'react';

interface Props {
  id: string;
  screenshotUrl: string;
  width: number;
  height: number;
  date: Date;
  flagged: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const ScreenshotActivityItem: React.FC<Props> = ({
  id,
  screenshotUrl,
  width,
  height,
  date,
  flagged,
  onToggleFlag,
  onDelete,
}) => (
  <Card padding={0} className="!border-0 w-full min-w-0 overflow-hidden">
    <div className="relative">
      <img
        src={screenshotUrl}
        width={width}
        height={height}
        alt="screenshot"
        className="block w-full h-auto rounded-t-xl"
      />
      <div className="absolute inset-x-0.25 top-0.25 bottom-0 rounded-t-[11.5px] border-x border-t border-white/50 pointer-events-none" />
      <div className="absolute inset-x-0 top-0 bottom-0 rounded-t-[12px] border-x border-t border-black/30 pointer-events-none" />
    </div>
    <Divider />
    <HStack
      justify="between"
      gap={2}
      className="border-x border-b border-stone-200 p-3 rounded-b-xl"
    >
      <Text
        as="time"
        dateTime={date.toISOString()}
        variant="captionSubtle"
        className="@lg/main:text-sm"
      >
        {formatTime(date)}
      </Text>
      {(onToggleFlag || onDelete) && (
        <HStack gap={2} className="relative">
          {flagged && (
            <div className="absolute w-120 h-40 rounded-[100%] -left-40 -bottom-24 [background:radial-gradient(#ddbb5535,transparent_70%)]" />
          )}
          <Tooltip
            content={
              flagged
                ? `Flagged items won't be deleted for 60 days`
                : `Flag to prevent deletion for 60 days`
            }
          >
            <Button
              type="button"
              onClick={() => onToggleFlag?.(id)}
              icon={FlagIcon}
              fillIcon={flagged}
              variant={flagged ? `selected` : `ghost`}
            >
              {flagged ? `Flagged` : `Flag`}
            </Button>
          </Tooltip>
          <Button type="button" onClick={() => onDelete?.(id)} icon={TrashIcon}>
            Delete
          </Button>
        </HStack>
      )}
    </HStack>
  </Card>
);

export default ScreenshotActivityItem;
