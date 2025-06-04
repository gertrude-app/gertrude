import React from 'react';
import { Button } from '@shared/components';
import type { ActivityFeedItem } from './UserActivityFeed';
import KeystrokesViewer from './KeystrokesViewer';
import ScreenshotViewer from './ScreenshotViewer';

const DeletableActivityChunks: React.FC<{
  items: ActivityFeedItem[];
  chunkSize: number;
  deleteItems: (ids: UUID[]) => unknown;
  flagItem: (id: UUID) => unknown;
  highlightSuspensionActivity: boolean;
}> = ({ items, deleteItems, flagItem, chunkSize, highlightSuspensionActivity }) => (
  <>
    {chunkedRenderTasks(items, chunkSize, highlightSuspensionActivity)
      .flat(1)
      .map((item) => {
        switch (item.type) {
          case `item`:
            return (
              <Item
                key={item.item.id}
                item={item.item}
                flagItem={() => flagItem(item.item.id)}
                deleteItem={() => deleteItems([item.item.id])}
              />
            );
          case `suspension_group`:
            return (
              <div
                key={`${item.items[0]?.id ?? ``}-suspension-group`}
                className="ml-2 md:-ml-6 mt-4 pl-4 md:pl-5 rounded-l-3xl border-4 border-r-0 border-red-500/60"
              >
                <div className="bg-slate-100 md:bg-slate-50 -mt-4 pl-3 font-medium text-lg text-red-600">
                  During filter suspension
                </div>
                <div className="flex flex-col gap-8 pt-2 pb-4">
                  {item.items.map((item) => (
                    <Item
                      key={item.id}
                      item={item}
                      flagItem={() => flagItem(item.id)}
                      deleteItem={() => deleteItems([item.id])}
                    />
                  ))}
                </div>
                <div className="bg-slate-100 md:bg-slate-50 h-2 -mb-1 ml-8"></div>
              </div>
            );
          default: // @link https://github.com/typescript-eslint/typescript-eslint/issues/2841
            return (
              <div
                key={`${item.ids[item.ids.length - 1] ?? ``}-delete-btn`}
                className="flex justify-center pb-8"
              >
                <Button
                  type="button"
                  color="secondary-on-violet-bg"
                  className="ScrollTop"
                  onClick={() => deleteItems(item.ids)}
                >
                  Delete previous {item.ids.length} items
                </Button>
              </div>
            );
        }
      })}
  </>
);

export default DeletableActivityChunks;

const Item: React.FC<{
  item: ActivityFeedItem;
  deleteItem: () => unknown;
  flagItem: () => unknown;
}> = ({ item, deleteItem, flagItem }) => {
  if (item.type === `Screenshot`) {
    return (
      <ScreenshotViewer
        url={item.url}
        width={item.width}
        height={item.height}
        onApprove={deleteItem}
        onFlag={flagItem}
        flagged={item.flagged}
        date={new Date(item.date)}
        duringSuspension={item.duringSuspension}
      />
    );
  } else {
    return (
      <KeystrokesViewer
        strokes={item.line}
        application={item.appName}
        onApprove={deleteItem}
        duringSuspension={item.duringSuspension}
        onFlag={flagItem}
        flagged={item.flagged}
        date={new Date(item.date)}
      />
    );
  }
};

export type Chunkable = {
  id: UUID;
  type: `Screenshot` | `KeystrokeLine`;
  duringSuspension: boolean;
  date: ISODateString;
};

type ActivityRenderTask<T extends Chunkable> =
  | { type: `item`; item: T }
  | { type: `suspension_group`; items: T[] }
  | { type: `delete_btn`; ids: UUID[] };

// an extraction of core logic without rendering for testability
export function chunkedRenderTasks<T extends Chunkable>(
  items: T[],
  chunkSize: number,
  highlightSuspensionActivity: boolean,
): Array<ActivityRenderTask<T>[]> {
  const ids: UUID[] = [];
  const chunkedTasks: Array<ActivityRenderTask<T>[]> = [];
  const numChunks = Math.ceil(items.length / chunkSize);

  for (let chunkIndex = 0; chunkIndex < numChunks; chunkIndex++) {
    const tasks: ActivityRenderTask<T>[] = [];
    const chunkOffset = chunkIndex * chunkSize;
    const chunkItems = items.slice(chunkOffset, chunkOffset + chunkSize);
    let suspensionBuffer: T[] = [];

    for (let i = 0; i < chunkItems.length; i++) {
      const item = chunkItems[i];
      if (!item) continue;
      const isLastItem = chunkItems[chunkItems.length - 1]?.id === item.id;
      const finishingSuspension =
        (!item.duringSuspension && suspensionBuffer.length > 0) ||
        (isLastItem && item.duringSuspension);

      if (item.duringSuspension && highlightSuspensionActivity) {
        suspensionBuffer.push(item);
      }

      if (finishingSuspension && highlightSuspensionActivity) {
        if (shouldBeMergedIntoSuspensionGroup(item, chunkItems, i)) {
          item.duringSuspension = true;
          suspensionBuffer.push(item);
        } else {
          tasks.push({ type: `suspension_group`, items: suspensionBuffer });
          suspensionBuffer = [];
        }
      }

      if (!item.duringSuspension || !highlightSuspensionActivity) {
        tasks.push({ type: `item`, item });
      }

      ids.push(item.id);
    }

    if (chunkIndex < numChunks - 1) {
      const toDelete = [...ids];
      tasks.push({ type: `delete_btn`, ids: toDelete });
    }
    chunkedTasks.push(tasks);
  }

  return chunkedTasks;
}

// because of the way the macapp emits activity events
// we sometimes get one or two keystroke lines near the
// end of a suspension period marked as not during suspension.
// this helps fold those into a suspension group so we don't
// end up with one or two un-suspended keystroke lines
// in the middle of a bunch of suspended ones
function shouldBeMergedIntoSuspensionGroup(
  item: Chunkable,
  items: Chunkable[],
  index: number,
): boolean {
  if (item.type === `Screenshot`) return false;
  const prev = items[index - 1];
  if (!prev) return false;
  const prevDate = new Date(prev.date);
  // if we can peek ahead a few and find a suspended item within 4 minutes
  // while only skipping over keystroke lines, then we should merge
  for (const peek of items.slice(index + 1, index + 5)) {
    if (!peek.duringSuspension) continue;
    if (peek.type === `KeystrokeLine`) return false;
    const peekDate = new Date(peek.date);
    const diff = prevDate.getTime() - peekDate.getTime();
    if (diff < 1000 * 60 * 4) {
      return true;
    }
  }
  return false;
}
