import React from 'react';
import cx from 'classnames';

interface Props {
  className?: string;
}

const Loading: React.FC<Props> = ({ className }) => {
  return (
    <div className={cx('w-16 h-14 flex items-start justify-between', className)}>
      <div className="rounded-full bg-gradient-to-tr from-indigo-500 to-fuchsia-500 animate-[loader-bounce_1.5s_0.1s_ease-out_infinite]" />
      <div className="rounded-full bg-gradient-to-tr from-indigo-500 to-fuchsia-500 animate-[loader-bounce_1.5s_0.2s_ease-out_infinite]" />
      <div className="rounded-full bg-gradient-to-tr from-indigo-500 to-fuchsia-500 animate-[loader-bounce_1.5s_0.3s_ease-out_infinite]" />
    </div>
  );
};

export default Loading;
