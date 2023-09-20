import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@shared/components';
import { UndoMainPadding } from '../../Chrome/Chrome';
import EmptyState from '../../EmptyState';
import KeystrokesViewer from './KeystrokesViewer';
import ScreenshotViewer from './ScreenshotViewer';
import FeedHeader from './FeedHeader';
import ReviewDayWrapper from './ReviewDayWrapper';

interface Screenshot {
  type: 'Screenshot';
  width: number;
  height: number;
  url: string;
  duringSuspension: boolean;
}

interface KeystrokeLine {
  type: 'KeystrokeLine';
  appName: string;
  line: string;
  duringSuspension: boolean;
}

export type ActivityFeedItem = (Screenshot | KeystrokeLine) & {
  id: UUID;
  ids: UUID[];
  date: string;
  deleted?: boolean;
};

interface Props {
  date: Date;
  items: ActivityFeedItem[];
  numDeleted: number;
  deleteItems(ids: UUID[]): unknown;
  chunkSize?: number;
}

const UserActivityFeed: React.FC<Props> = ({
  date,
  items,
  numDeleted,
  deleteItems,
  chunkSize = 100,
}) => {
  const navigate = useNavigate();
  return (
    <UndoMainPadding className="px-0 md:px-8 lg:px-10 py-5 md:py-10 pt-0 md:pt-4 pb-16 flex flex-col bg-slate-100 md:bg-slate-50">
      <FeedHeader date={date} numItems={items.length} numDeleted={numDeleted} />
      {items.length > 0 ? (
        <ReviewDayWrapper>
          {deleteableChunks(items, chunkSize, deleteItems)}
          <Button
            className="ScrollTop self-center"
            type="button"
            onClick={() => {
              deleteItems(items.map((item) => item.id));
              setTimeout(() => navigate(`..`, { replace: true }), 100);
            }}
            color="primary"
            size="large"
          >
            <i className="fa-solid fa-thumbs-up mr-2" />
            Approve all
          </Button>
        </ReviewDayWrapper>
      ) : (
        <FeedCaughtUp />
      )}
    </UndoMainPadding>
  );
};

export default UserActivityFeed;

export const FeedCaughtUp: React.FC = () => (
  <EmptyState
    heading="All caught up!"
    secondaryText="Nothing left to review for this day."
    icon="image"
    buttonText="Back to activity"
    buttonIcon="arrow-left"
    action="../"
    className="max-w-7xl"
  />
);

export function deleteableChunks(
  items: ActivityFeedItem[],
  chunkSize: number,
  deleteItems: (ids: UUID[]) => unknown,
): JSX.Element[] {
  let numItemsRendered = 0;
  const ids: UUID[] = [];
  const elements: JSX.Element[] = [];
  const numChunks = Math.ceil(items.length / chunkSize);

  for (let chunkIndex = 0; chunkIndex < numChunks; chunkIndex++) {
    const chunkOffset = chunkIndex * chunkSize;
    const chunkItems = items.slice(chunkOffset, chunkOffset + chunkSize);

    let bufferingSuspensionItems = false;
    let buffer: JSX.Element[] = [];

    for (const item of chunkItems) {
      const isLastItem = chunkItems.indexOf(item) === chunkItems.length - 1;
      const finishingSuspension =
        (!item.duringSuspension && bufferingSuspensionItems) ||
        (isLastItem && item.duringSuspension);
      bufferingSuspensionItems = item.duringSuspension;

      if (item.duringSuspension) {
        buffer.push(renderItem(item, () => deleteItems([item.id]), numItemsRendered));
      }
      if (finishingSuspension) {
        elements.push(
          <div
            key={buffer[0]?.key}
            className="ml-2 md:-ml-6 mt-4 pl-4 md:pl-5 rounded-l-3xl border-4 border-r-0 border-red-500/60"
          >
            <div className="bg-slate-100 md:bg-slate-50 -mt-4 pl-3 font-medium text-lg text-red-600">
              During filter suspension
            </div>
            <div className="flex flex-col gap-8 pt-2 pb-4">{buffer}</div>
            <div className="bg-slate-100 md:bg-slate-50 h-2 -mb-1 ml-8"></div>
          </div>,
        );
        buffer = [];
      }
      if (!item.duringSuspension) {
        elements.push(renderItem(item, () => deleteItems([item.id]), numItemsRendered));
      }
      ids.push(item.id);
      numItemsRendered++;
    }

    if (chunkIndex < numChunks - 1) {
      const toDelete = [...ids];
      elements.push(
        <div
          key={`${ids[ids.length - 1] ?? ``}-separator`}
          className="flex justify-center pb-8"
        >
          <Button
            type="button"
            color="secondary-on-violet-bg"
            className="ScrollTop"
            onClick={() => deleteItems(toDelete)}
          >
            Approve previous {[...ids].length} items
          </Button>
        </div>,
      );
    }
  }
  return elements;
}

function renderItem(
  item: ActivityFeedItem,
  deleteItem: () => unknown,
  numRendered: number,
): JSX.Element {
  if (item.type === `Screenshot`) {
    return (
      <ScreenshotViewer
        key={item.id}
        url={item.url}
        width={item.width}
        height={item.height}
        onApprove={deleteItem}
        date={new Date(item.date)}
        duringSuspension={item.duringSuspension}
        lazy={numRendered > 10}
      />
    );
  } else {
    return (
      <KeystrokesViewer
        key={item.id}
        strokes={item.line}
        application={item.appName}
        onApprove={deleteItem}
        duringSuspension={item.duringSuspension}
        date={new Date(item.date)}
      />
    );
  }
}
