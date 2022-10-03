import React from 'react';
import { Link } from 'react-router-dom';
import Button from '../../../../Button';
import PartyMessage from '../../../../PartyMessage';
import { UndoMainPadding } from '../../../Chrome/Chrome';
import KeystrokesViewer from './KeystrokesViewer';
import ScreenshotViewer from './ScreenshotViewer';

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

export type ActivityItem = (Screenshot | KeystrokeLine) & {
  id: UUID;
  ids: UUID[];
  date: string;
  deleted?: boolean;
};

interface Props {
  date: Date;
  items: ActivityItem[];
  numDeleted: number;
  deleteItems(ids: UUID[]): unknown;
  chunkSize?: number;
}

const UserActivityReviewDay: React.FC<Props> = ({
  date,
  items,
  numDeleted,
  deleteItems,
  chunkSize = 100,
}) => (
  <UndoMainPadding>
    <header className="flex items-center justify-between py-4 px-6 border-b-2 bg-white">
      <div className="flex items-center text-md sm:text-l">
        <Link
          to="../"
          className="flex items-center mr-4 text-gray-400 antialiased hover:text-gray-600 transition duration-75"
        >
          <i className="fa fa-chevron-left mr-2" aria-hidden /> Back
        </Link>
        <h1 className="font-medium text-gray-800">{date.toLocaleDateString()}</h1>
      </div>
      {items.length > 0 && (
        <div className="text-gray-700 self-end sm:self-center flex items-center space-x-0.5 sm:space-x-1">
          <span className="font-bold sm:text-lg">{numDeleted}</span>
          <span className="hidden sm:inline">out of</span>
          <span className="sm:hidden">/</span>
          <span className="font-bold sm:text-lg">{numDeleted + items.length}</span>
          <span className="hidden sm:inline">items reviewed</span>
        </div>
      )}
    </header>
    {items.length > 0 ? (
      <div
        id="delete-focus"
        className="px-0 md:px-8 lg:px-10 py-5 md:py-10 pb-16 bg-gray-200 md:bg-transparent flex-grow space-y-8 flex flex-col"
      >
        {deleteableChunks(items, chunkSize, deleteItems)}
        <Button
          className="self-center"
          type="button"
          onClick={() => deleteItems(items.map((item) => item.id))}
          color="primary-violet"
        >
          Approve all
        </Button>
      </div>
    ) : (
      <div className="flex justify-center p-8">
        <PartyMessage>Nothing to review for this day</PartyMessage>
      </div>
    )}
  </UndoMainPadding>
);

export default UserActivityReviewDay;

function deleteableChunks(
  items: ActivityItem[],
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
        <div key={`${ids[ids.length - 1] ?? ``}-separator`} className="self-center pb-8">
          <Button
            className="self-center"
            type="button"
            small
            onClick={() => {
              deleteItems(toDelete);
              // sometimes scrolling to top seems to fail, possibly because
              // the repaint hasn't finished, or maybe because of react re-renders,
              // so, retry a couple times to hopefully land in the right spot
              setTimeout(scrollToTop, 0);
              setTimeout(scrollToTop, 50);
              setTimeout(scrollToTop, 150);
            }}
            color="primary-violet"
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
  item: ActivityItem,
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
