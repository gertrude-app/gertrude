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
}

const UserActivityReviewDay: React.FC<Props> = ({
  date,
  items,
  numDeleted,
  deleteItems,
}) => (
  <UndoMainPadding>
    <header className="flex zflex-col zsm:flex-row items-center justify-between py-4 px-6 border-b-2 bg-white">
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
          <span className="font-bold sm:text-lg">
            {numDeleted + items.filter((item) => !item.deleted).length}
          </span>
          <span className="hidden sm:inline">items reviewed</span>
        </div>
      )}
    </header>
    {items.length > 0 ? (
      <div className="px-0 md:px-8 lg:px-10 py-5 md:py-10 bg-gray-200 md:bg-transparent flex-grow space-y-8 flex flex-col">
        {items
          .filter((item) => !item.deleted)
          .map((item) => renderItem(item, () => deleteItems([item.id])))}
        <Button
          className="self-center"
          type="button"
          onClick={() => {}}
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

function renderItem(item: ActivityItem, deleteItem: () => unknown): JSX.Element {
  if (item.type === `Screenshot`) {
    return (
      <ScreenshotViewer
        key={item.id}
        url={item.url}
        width={item.width}
        height={item.height}
        onApprove={deleteItem}
        date={new Date(item.date)}
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
