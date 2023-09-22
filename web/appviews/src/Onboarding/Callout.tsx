import React from 'react';
import cx from 'classnames';

interface Props {
  children: React.ReactNode;
  heading: string;
  type: 'info' | 'warning';
  className?: string;
}

const Callout: React.FC<Props> = ({ children, heading, type, className }) => (
  <div
    className={cx(
      `border border-slate-200 p-6 pt-8 rounded-2xl relative max-w-3xl`,
      className,
    )}
  >
    <div className="absolute left-4 -top-6 w-12 h-12 rounded-full bg-slate-50 flex justify-center items-center">
      <i
        className={cx(
          `fa-solid text-3xl`,
          type === `info`
            ? `fa-circle-info text-fuchsia-400`
            : `fa-circle-exclamation text-orange-300`,
        )}
      />
    </div>
    <h3 className="text-lg font-semibold text-slate-700">{heading}</h3>
    <div className="text-slate-500 mt-2">{children}</div>
  </div>
);

export default Callout;
