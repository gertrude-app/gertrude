import React from 'react';
import cx from 'classnames';

interface Props {
  className?: string;
  withWhiteBg?: boolean;
}

const Loading: React.FC<Props> = ({ className, withWhiteBg }) => {
  if (withWhiteBg) {
    return (
      <div
        className={cx(
          `bg-white w-32 h-32 rounded-[30px] xrotate-45 flex justify-center items-center`,
          className,
        )}
      >
        <Animation className="-rotate-45x" />
      </div>
    );
  }
  return <Animation className={className} />;
};

export default Loading;

const Animation: React.FC<{ className?: string }> = ({ className }) => {
  return (
    <div className={cx(`w-16 h-14 flex items-start justify-between`, className)}>
      <div className="rounded-full bg-gradient-to-tr from-indigo-500 to-fuchsia-500 animate-[loader-bounce_1.5s_0.1s_ease-out_infinite]" />
      <div className="rounded-full bg-gradient-to-tr from-indigo-500 to-fuchsia-500 animate-[loader-bounce_1.5s_0.2s_ease-out_infinite]" />
      <div className="rounded-full bg-gradient-to-tr from-indigo-500 to-fuchsia-500 animate-[loader-bounce_1.5s_0.3s_ease-out_infinite]" />
    </div>
  );
};
