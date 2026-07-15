import { Card, Divider, HStack, Text } from '@gertrude/ui';
import { formatTime } from '@shared/datetime';
import React from 'react';
import ActivityItemActions from './ActivityItemActions';

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
      <ActivityItemActions
        id={id}
        flagged={flagged}
        onToggleFlag={onToggleFlag}
        onDelete={onDelete}
      />
    </HStack>
  </Card>
);

export default KeylogActivityItem;
