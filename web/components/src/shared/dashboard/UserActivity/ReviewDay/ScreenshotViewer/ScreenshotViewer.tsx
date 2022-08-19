import React from 'react';
import Button from '../../../../Button';
import ActivityItemTime from '../ActivityItemTime';

type Props = {
  className?: string;
  url: string;
  width: number;
  height: number;
  date: Date;
};

const ScreenshotViewer: React.FC<Props> = ({ url, className, date, width, height }) => (
  <div
    className={`border-y md:border-x md:rounded-xl md:shadow-lg bg-white max-w-7xl ${className}`}
  >
    <div className="md:mx-4 mb-3 sm:mb-0 md:mt-4 flex justify-center">
      <img
        className="md:rounded-lg w-full max-w-4xl shadow-inner"
        src={url}
        width={width}
        height={height}
        alt="user screenshot"
      />
    </div>
    <div className="px-4 py-3 sm:py-4 pt-0 flex justify-between items-start">
      <ActivityItemTime date={date} />
      <Button color="secondary-white" small type="button" onClick={() => {}}>
        Approve
      </Button>
    </div>
  </div>
);

export default ScreenshotViewer;
