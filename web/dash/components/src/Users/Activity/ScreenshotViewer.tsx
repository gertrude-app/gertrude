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
  duringSuspension: boolean;
  lazy?: boolean;
};

const ScreenshotViewer: React.FC<Props> = ({
  url,
  className,
  date,
  width,
  height,
  onApprove,
  duringSuspension,
  lazy = false,
}) => (
  <div
    className={cx(
      `md:shadow-lg md:shadow-slate-300/50 max-w-7xl bg-white border-slate-200 rounded-2xl border-[0.5px]`,
      !duringSuspension && `!border-x-0 md:!border-x-[0.5px]`,
      className,
    )}
  >
    <div className={cx(`md:mx-4 mb-3 sm:mb-0 md:mt-4 flex justify-center rounded-xl`)}>
      <img
        className="rounded-t-2xl md:rounded-b-2xl shadow-inner w-full md:w-auto"
        src={url}
        width={width}
        height={height}
        loading={lazy && !isScreenshotTest() ? `lazy` : `eager`}
        alt="child screenshot"
      />
    </div>
    <div className="px-4 py-3 sm:py-4 pt-0 flex justify-between items-center">
      <ActivityItemTime date={date} />
      <Button color="tertiary" type="button" onClick={onApprove}>
        Approve
      </Button>
    </div>
  </div>
);

export default ScreenshotViewer;
