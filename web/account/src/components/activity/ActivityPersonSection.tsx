import { Button, HStack, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { TrashIcon } from 'lucide-react';
import React from 'react';
import type { ActivityChunk, ActivityItem } from '#/lib/activity';
import KeylogActivityItem from './KeylogActivityItem';
import ScreenshotActivityItem from './ScreenshotActivityItem';
import CardContainer from '#/components/layout/CardContainer';
import { chunkActivityBySuspension } from '#/lib/activity';

interface Props {
  personId: string;
  personName: string;
  items: ActivityItem[];
  showHeading?: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
  onDeleteAll?: (personId: string) => void;
}

const ActivityPersonSection: React.FC<Props> = ({
  personId,
  personName,
  items,
  showHeading = true,
  onToggleFlag,
  onDelete,
  onDeleteAll,
}) => {
  const chunkedItems = chunkActivityBySuspension(items);

  return (
    <VStack gap={3}>
      {showHeading && <Text variant="heading">{personName}'s activity</Text>}
      <CardContainer className="flex flex-col gap-6">
        {chunkedItems.map((chunk, index) => (
          <ActivitySuspensionChunk
            key={`${chunk.type}-${index}-${chunk.items[0]?.id ?? `empty`}`}
            chunk={chunk}
            onToggleFlag={onToggleFlag}
            onDelete={onDelete}
          />
        ))}
        {onDeleteAll && (
          <HStack justify="center">
            <Button type="button" onClick={() => onDeleteAll(personId)} icon={TrashIcon}>
              Delete all {personName}'s activity
            </Button>
          </HStack>
        )}
      </CardContainer>
    </VStack>
  );
};

interface ActivitySuspensionChunkProps {
  chunk: ActivityChunk;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
}

const ActivitySuspensionChunk: React.FC<ActivitySuspensionChunkProps> = ({
  chunk,
  onToggleFlag,
  onDelete,
}) => (
  <div
    className={cx(
      chunk.type === `duringSuspension` &&
        `pl-2.25 @lg/main:pl-2.5 @xl/main:pl-3.5 @3xl/main:pl-0`,
    )}
  >
    {chunk.type === `duringSuspension` && (
      <HStack align="end" gap={2} className="-ml-3.5">
        <div className="rounded-tl-full w-5 h-5 border-t-3 border-l-3 border-red-600 -mb-0.25" />
        <span className="relative -top-1.5 font-medium text-red-700/80">
          During suspension
        </span>
      </HStack>
    )}
    <HStack align="stretch">
      {chunk.type === `duringSuspension` && (
        <div className="top-0 bottom-0 w-0.75 bg-red-600 relative -mr-1 -left-3.5 shrink-0" />
      )}
      <VStack gap={6} className="flex-grow">
        {chunk.items.map((item) =>
          item.type === `screenshot` ? (
            <ScreenshotActivityItem
              key={item.id}
              id={item.id}
              screenshotUrl={item.url}
              width={item.width}
              height={item.height}
              date={item.date}
              flagged={item.flagged}
              onToggleFlag={onToggleFlag}
              onDelete={onDelete}
            />
          ) : (
            <KeylogActivityItem
              key={item.id}
              id={item.id}
              text={item.text}
              applicationName={item.applicationName}
              date={item.date}
              flagged={item.flagged}
              onToggleFlag={onToggleFlag}
              onDelete={onDelete}
            />
          ),
        )}
      </VStack>
    </HStack>
    {chunk.type === `duringSuspension` && (
      <HStack align="end" gap={2} className="-ml-3.5">
        <div className="rounded-bl-full w-8 h-5 border-b-3 border-l-3 border-red-600 -mt-0.25" />
      </HStack>
    )}
  </div>
);

export default ActivityPersonSection;
