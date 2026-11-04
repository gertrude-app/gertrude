import { Button, HStack, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { TrashIcon } from 'lucide-react';
import React, { useRef } from 'react';
import type { ActivityChunk, ActivityItem } from '#/lib/activity';
import KeylogActivityItem from './KeylogActivityItem';
import ScreenshotActivityItem from './ScreenshotActivityItem';
import CardContainer from '#/components/layout/CardContainer';
import { chunkActivityForDeletion } from '#/lib/activity';

interface Props {
  personId: string;
  personName: string;
  items: ActivityItem[];
  showHeading?: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
  onDeleteItems?: (ids: string[]) => void;
  chunkSize?: number;
  onDeleteAll?: (personId: string) => void;
}

const ActivityPersonSection: React.FC<Props> = ({
  personId,
  personName,
  items,
  showHeading = true,
  onToggleFlag,
  onDelete,
  onDeleteItems,
  chunkSize,
  onDeleteAll,
}) => {
  const sectionRef = useRef<HTMLDivElement>(null);
  const batches = chunkActivityForDeletion(items, chunkSize);
  const hasFlaggedItems = items.some((item) => item.flagged);
  const allItemsFlagged = items.every((item) => item.flagged);

  return (
    <VStack gap={3} ref={sectionRef}>
      {showHeading && <Text variant="heading">{personName}'s activity</Text>}
      <CardContainer className="flex flex-col gap-6">
        {batches.map(({ chunks, previousItems }) => (
          <React.Fragment key={chunks[0]?.items[0]?.id}>
            {chunks.map((chunk) => (
              <ActivitySuspensionChunk
                key={chunk.items[0]?.id}
                chunk={chunk}
                onToggleFlag={onToggleFlag}
                onDelete={onDelete}
              />
            ))}
            {onDeleteItems && previousItems.length > 0 && (
              <HStack justify="center">
                <Button
                  type="button"
                  icon={TrashIcon}
                  disabled={previousItems.every((item) => item.flagged)}
                  onClick={() => {
                    onDeleteItems(previousItems.map((item) => item.id));
                    requestAnimationFrame(() => {
                      sectionRef.current?.scrollIntoView({ block: `start` });
                    });
                  }}
                >
                  {previousItems.some((item) => item.flagged)
                    ? `Delete unflagged activity in previous ${previousItems.length} items`
                    : `Delete previous ${previousItems.length} items`}
                </Button>
              </HStack>
            )}
          </React.Fragment>
        ))}
        {onDeleteAll && (
          <HStack justify="center">
            <Button
              type="button"
              onClick={() => onDeleteAll(personId)}
              icon={TrashIcon}
              disabled={allItemsFlagged}
            >
              {`Delete all ${personName}'s${
                hasFlaggedItems ? ` unflagged` : ``
              } activity`}
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
