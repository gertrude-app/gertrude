import React from 'react';
import cx from 'classnames';

interface Props {
  onClick(): void;
  children: React.ReactNode;
  className?: string;
}

const TellMeMoreButton: React.FC<Props> = ({ onClick, children, className }) => {
  return (
    <button
      onClick={onClick}
      className={cx(
        'font-medium text-violet-500 hover:bg-violet-100 rounded-xl transition-[background-color,transform] duration-200 px-6 py-2 active:scale-[97%] active:bg-violet-200',
        className,
      )}
    >
      <i className="fa-solid far fa-circle-question mr-2" />
      <span>{children}</span>
    </button>
  );
};

export default TellMeMoreButton;
