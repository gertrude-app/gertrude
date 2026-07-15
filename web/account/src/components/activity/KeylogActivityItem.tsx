import { Button, Card, Divider, HStack, Text, Tooltip } from '@gertrude/ui';
import { formatTime } from '@shared/datetime';
import { FlagIcon, TrashIcon } from 'lucide-react';
import React from 'react';

interface Props {
  id: string;
  text: string;
  applicationName: string;
  date: Date;
  flagged: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const KeylogActivityItem: React.FC<Props> = ({
  id,
  text,
  applicationName,
  date,
  flagged,
  onToggleFlag,
  onDelete,
}) => (
  <Card padding={0} className="overflow-hidden">
    <Text
      as="p"
      variant="code"
      className="@lg/main:text-base p-3 bg-stone-50 flex flex-col"
    >
      {text.split(`\n`).map((line, index) => (
        <span key={`${index}-${line}`}>{line}</span>
      ))}
    </Text>
    <Divider />
    <HStack justify="between" gap={2} className="p-3">
      <Text variant="captionSubtle" className="@lg/main:text-sm">
        <time dateTime={date.toISOString()}>{formatTime(date)}</time>
        {` · Typed in `}
        <Text variant="bodyStrong" className="@lg/main:text-sm">
          {applicationName}
        </Text>
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

export default KeylogActivityItem;
