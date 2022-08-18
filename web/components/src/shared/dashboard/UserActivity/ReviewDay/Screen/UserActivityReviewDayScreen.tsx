import React from 'react';
import { Link } from 'react-router-dom';
import Button from '../../../../Button';
import KeystrokesViewer from '../KeystrokesViewer';
import ScreenshotViewer from '../ScreenshotViewer';

// temp
interface Screenshot {
  __typename: 'Screenshot';
  id: UUID;
  width: number;
  height: number;
  url: string;
}

interface KeystrokeLine {
  __typename: 'KeystrokeLine';
  id: UUID;
  appName: string;
  line: string;
}

interface Props {
  date: Date;
  numReviewedItems: number;
  items: Array<KeystrokeLine | Screenshot>;
}

const UserActivityReviewDayScreen: React.FC<Props> = ({
  date,
  numReviewedItems,
  items,
}) => (
  <main className="flex flex-col min-h-screen">
    <header className="flex flex-col sm:flex-row itesm-center justify-between py-4 px-6 border-b-2 bg-gray-50">
      <div className="flex items-center">
        <Link
          to="/monitoring"
          className="flex items-center mr-6 text-gray-500 hover:text-gray-600 transition duration-75 text-lg"
        >
          <i className="fa fa-chevron-left text-lg mr-2" /> Back
        </Link>
        <h1 className="text-xl font-medium text-gray-800">{date.toLocaleDateString()}</h1>
      </div>
      <h3 className="text-gray-700 self-end sm:self-center mt-2 sm:mt-0">
        <span className="font-bold text-lg">{numReviewedItems}</span> out of{` `}
        <span className="font-bold text-lg">{items.length}</span> items reviewed
      </h3>
    </header>
    <div className="px-0 md:px-5 lg:px-10 py-5 md:py-10 bg-gray-200 md:bg-gray-50 flex-grow space-y-8 flex flex-col">
      {items.map((item) => {
        // @TEMP
        if (item.__typename === `Screenshot`) {
          return <ScreenshotViewer key={item.id} image={item.url} date={date} />;
        } else {
          return (
            <KeystrokesViewer
              key={item.id}
              strokes={item.line}
              application={item.appName}
              {...item}
              date={date}
            />
          );
        }
      })}
      <Button
        className="self-center"
        type="button"
        onClick={() => {}}
        color="primary-violet"
      >
        Approve all
      </Button>
    </div>
  </main>
);

export default UserActivityReviewDayScreen;
