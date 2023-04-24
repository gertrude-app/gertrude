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
}

interface KeystrokeLine {
  type: 'KeystrokeLine';
  appName: string;
  line: string;
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
    <UndoMainPadding className="px-0 md:px-8 lg:px-10 py-5 md:py-10 pt-0 md:pt-4 pb-16 flex flex-col">
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
        <div className="">
          <EmptyState
            heading={`All caught up!`}
            secondaryText={`Nothing left to review for this day.`}
            icon={`image`}
            buttonText={`Back to activity`}
            buttonIcon="arrow-left"
            action={`../`}
            className="max-w-7xl"
          />
        </div>
      )}
    </UndoMainPadding>
  );
};

export default UserActivityFeed;

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

    for (const item of chunkItems) {
      ids.push(item.id);
      elements.push(renderItem(item, () => deleteItems([item.id]), numItemsRendered));
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
            onClick={() => {
              deleteItems(toDelete);
              // sometimes scrolling to top seems to fail, possibly because
              // the repaint hasn't finished, or maybe because of react re-renders,
              // so, retry a couple times to hopefully land in the right spot
              setTimeout(scrollToTop, 0);
              setTimeout(scrollToTop, 50);
              setTimeout(scrollToTop, 150);
            }}
          >
            Approve previous {[...ids].length} items
          </Button>
        </div>,
      );
    }
  }
  return elements;
}

function scrollToTop(): void {
  document.getElementById(`delete-focus`)?.scrollIntoView({
    behavior: `smooth`,
  });
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
        date={new Date(item.date)}
      />
    );
  }
}
