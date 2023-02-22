import React from 'react';
import cx from 'classnames';
import { Button, isScreenshotTest } from '@shared/components';
import ActivityItemTime from './ActivityItemTime';

type Props = {
  className?: string;
  url: string;
  width: number;
  height: number;
  onApprove(): unknown;
  date: Date;
  lazy?: boolean;
};

const ScreenshotViewer: React.FC<Props> = ({
  url,
  className,
  date,
  width,
  height,
  onApprove,
  lazy = false,
}) => (
  <div
    className={cx(
      `border-y md:border-x md:rounded-xl md:shadow-lg bg-white max-w-7xl`,
      className,
    )}
  >
    <div className="md:mx-4 mb-3 sm:mb-0 md:mt-4 flex justify-center bg-violet-100/50 rounded-lg">
      <img
        className="md:rounded-lg shadow-inner"
        src={url}
        width={width}
        height={height}
        loading={lazy && !isScreenshotTest() ? `lazy` : `eager`}
        alt="user screenshot"
      />
    </div>
    <div className="px-4 py-3 sm:py-4 pt-0 flex justify-between items-start">
      <ActivityItemTime date={date} />
      <Button color="tertiary" size="medium" type="button" onClick={onApprove}>
        Approve
      </Button>
    </div>
  </div>
);

export default ScreenshotViewer;
